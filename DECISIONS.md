# Architecture & Implementation Decisions — NEXU RouteRunner

This document details critical ambiguous requirements encountered during the design and development of **NEXU RouteRunner**, along with the selected architectural solutions and rationales.

---

## Decision 1: Interpretation of Retry Count and Maximum Retries (S3)

### The Ambiguity
Requirement **S3** defines the retry schedule:
> - First retry after 2 seconds.
> - Second retry after 4 seconds.
> - Third retry after 8 seconds.
> - After the third retry failure, move the action to Needs attention.

In systems engineering, "retry limits" often have two interpretations:
1. **Three total attempts**: 1 initial attempt + 2 retry attempts.
2. **Three retries after the initial attempt**: 1 initial attempt + 3 retry attempts (total 4 attempts before Needs Attention).

### Selected Implementation
We implemented **Option 2: 1 initial attempt + 3 scheduled retries (total 4 attempts)**:
- **Initial attempt** (`retryCount == 0`): If it fails, schedules the 1st retry at `now + 2s`, incrementing `retryCount` to 1.
- **1st retry** (`retryCount == 1`): If it fails, schedules the 2nd retry at `now + 4s`, incrementing `retryCount` to 2.
- **2nd retry** (`retryCount == 2`): If it fails, schedules the 3rd retry at `now + 8s`, incrementing `retryCount` to 3.
- **3rd retry** (`retryCount == 3`): If it fails, the retry limit is exhausted. The action transitions to `SyncStatus.needsAttention` and `nextRetryTime` is cleared.

### Rationale
In mobile logistics environments with unstable cellular networks (elevators, basements, tunnels), network drops are frequently transient. Allowing three retries after the initial attempt gives sufficient exponential spread (total 14 seconds of backoff spacing) to recover from temporary disconnections before escalating to the agent for manual intervention.

---

## Decision 2: Delivery Undo Impact on State, History, and Sync (R5)

### The Ambiguity
Requirement **R5** states:
> Undo must:
> - Restore the stop to an appropriate editable state.
> - Restore route ordering.
> - Generate a new synchronization action.
> - Never delete the original delivery history.
> Allow Undo only within 60 seconds.

The specification leaves open:
1. Which specific workflow state the stop should revert to (`Pending` vs `Arrived`).
2. How the audit history should represent the cancellation.
3. How undo synchronization is sequenced relative to the original delivery action.

### Selected Implementation
1. **Target State**: The stop is reverted to `WorkflowStatus.arrived`.
   - The delivery timestamp is cleared to prevent further undo countdowns.
   - Recipient and confirmed packages remain visible or editable for correction.
2. **Audit History Integrity**: The historical `delivered` entry is **never mutated or deleted**. A new `DeliveryHistoryEntry` with status `WorkflowStatus.arrived` and note `"Delivery undone by agent within 60s window"` is appended to the audit trail.
3. **Route Ordering Restoration**: If the stop was moved or assigned custom order indices, `customOrder` is cleared, restoring the stop to its natural position in the route based on its delivery window and priority.
4. **Synchronization Action**: An `undoDelivered` sync action is enqueued with a unique UUID request ID and the next sequential `sequenceNumber` for that stop (`seqNum == 3` if arrived was 1 and delivered was 2).

### Rationale
Reverting to `Arrived` rather than `Pending` reflects physical reality: the driver has already arrived at the customer's doorstep and is correcting an accidental tap, a recipient name typo, or an altered situation. Appending an audit record rather than deleting historical records ensures compliance with delivery audit standards.

---

## Decision 3: Queue Blocking and Inter-Stop Independence (S4)

### The Ambiguity
Requirement **S4** specifies:
> Actions belonging to the same stop must reach the server in exactly the order they occurred.
> If an earlier action is waiting, retrying or requires attention:
> - Block later actions for that stop from overtaking it.
> - Preserve the original sequence numbers.
> - Allow unrelated stops to synchronize independently where safe.

The ambiguity centers on what happens to subsequent actions for Stop A when the head action for Stop A is in `SyncStatus.needsAttention`.

### Selected Implementation
1. **Per-Stop FIFO Pipeline**:
   - For any given `stopId`, actions are strictly sorted by `sequenceNumber` ascending.
   - The action at index 0 is the "head" action.
   - If the head action is in `needsAttention`, all subsequent actions for that stop are completely blocked from dispatching.
   - When the agent taps "Manual Retry", the head action resets to `pending` with `retryCount = 0`, enabling the pipeline to resume upon next tick.
2. **Inter-Stop Independence**:
   - The sync engine groups the queue by `stopId`.
   - A failure or retrying state on `STOP-001` does **not** block `STOP-002`, `STOP-003`, or any other independent stop from synchronizing immediately.

### Rationale
Allowing later actions for the same stop to overtake earlier actions would cause severe domain corruption (e.g. attempting to mark `Delivered` on the server before `Arrived` has been processed, or applying `Undo` before `Delivered`). Conversely, blocking all stops when one stop has an issue would cripple mobile performance. Grouping by `stopId` strikes the ideal balance between consistency and throughput.

---

## Decision 4: Calculation of Success Rate and On-Time Rate Denominators

### The Ambiguity
Requirement **Screen 4** suggests:
> Success rate = Delivered / Total stops × 100.
> On-time rate = On-time delivered / Delivered × 100.
> Define the calculation denominators explicitly.

Edge cases exist when:
1. `Total stops == 0` (e.g. empty route).
2. `Delivered == 0` (e.g. start of shift, where no deliveries have been completed yet).
3. Stops are delivered after their time window end.

### Selected Implementation
1. **Success Rate**:
   $$\text{Success Rate} = \begin{cases} \frac{\text{Delivered}}{\text{Total Stops}} \times 100 & \text{if Total Stops} > 0 \\ 0.0\% & \text{otherwise} \end{cases}$$
   - Denominator: All stops scheduled for the day (14 in our dataset), regardless of current status.
2. **On-Time Rate**:
   $$\text{On-Time Rate} = \begin{cases} \frac{\text{On-Time Delivered}}{\text{Delivered}} \times 100 & \text{if Delivered} > 0 \\ 0.0\% & \text{otherwise} \end{cases}$$
   - Denominator: Only stops that have been successfully marked `Delivered`.
   - A delivery is considered **On-Time** if `stop.deliveryTimestamp` is less than or equal to `windowEnd` (e.g. `10:00:00`). If delivered at `10:00:01` or later, it is considered late and not counted in the numerator.
   - When `Delivered == 0`, the rate evaluates gracefully to `0.0%` rather than `NaN` or dividing by zero.

### Rationale
Evaluating on-time rate against total stops rather than delivered stops would unfairly penalize drivers at 09:00 AM for afternoon stops that are not yet due. Evaluating against delivered stops accurately reflects the punctuality of completed work.
