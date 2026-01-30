# 🖼️ System Functional Diagrams

This document visualizes the core functional workflows of the Autonomous Medical Delivery Robot.

---

## 1. Face Training Workflow
**Goal**: Capture patient faces, train the LBPH recognizer, and serialize the model for runtime use.

![Face Training Workflow](C:/Users/aymen/.gemini/antigravity/brain/a7aa377e-464e-4848-a31e-4802a21c7641/face_training_workflow_1769774531313.png)

### Key Steps:
1.  **Capture**: Takes multiple snapshots to handle different angles/lighting.
2.  **Detection**: Validates that a face is actually present before saving.
3.  **Training**: Generates a unified model (`yml`) from all patient datasets.

---

## 2. Medicine Dispensing Sequence
**Goal**: Correctly dispense medicine using the specific 180° backward rotation rule.

![Medicine Dispensing Sequence](C:/Users/aymen/.gemini/antigravity/brain/a7aa377e-464e-4848-a31e-4802a21c7641/medicine_dispensing_sequence_1769774556779.png)

### The 180° Rule:
- Before aligning to the target medicine slot, the wheel **MUST** rotate 180° backward from its current position.
- This ensures mechanical agitation or reset logic as defined in requirements.
- **Sequence**: `Current` -> `Current + 180` -> `Target` -> `Open Door`.

---

## 3. Patient-Medicine Assignment Logic
**Goal**: Map a recognized face to a specific servo angle.

![Assignment Logic](C:/Users/aymen/.gemini/antigravity/brain/a7aa377e-464e-4848-a31e-4802a21c7641/assignment_logic_1769774578544.png)

### Data Flow:
1.  **Recognition**: The camera identifies "John Doe" (ID: 001).
2.  **Lookup**: The system checks the `assignments` table for `patient_id=001`.
3.  **Retrieval**: Finds linked `medicine_id` (e.g., Aspirin).
4.  **Action**: Looks up Aspirin's `angle` and rotates the servo.

---

## 4. Arduino Line Following Logic
**Goal**: Navigate the track and stop at black markers.

![Arduino Logic](C:/Users/aymen/.gemini/antigravity/brain/a7aa377e-464e-4848-a31e-4802a21c7641/arduino_logic_1769774598710.png)

### Stop & Resume Protocol:
- **Stop Condition**: All 5 sensors read BLACK (> Threshold).
- **Communication**: Sends `"STOP"` string over Serial to Raspberry Pi.
- **Wait State**: Arduino halts `loop()` until it receives `"RESUME"`.
