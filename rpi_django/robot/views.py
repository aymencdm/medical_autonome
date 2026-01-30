from rest_framework import viewsets, views
from rest_framework.response import Response
from .models import Patient, Medicine, Assignment
from .serializers import PatientSerializer, MedicineSerializer, AssignmentSerializer
from .hardware.state_machine import StateMachine, RobotMode
from .hardware.medicine_controller import MedicineController
from .hardware.servos import ServoController
from .hardware.face_recognizer import FaceRecognizer
from .hardware.config import CONFIG
from .hardware_manager import hardware

class PatientViewSet(viewsets.ModelViewSet):
    queryset = Patient.objects.all()
    serializer_class = PatientSerializer

class MedicineViewSet(viewsets.ModelViewSet):
    queryset = Medicine.objects.all()
    serializer_class = MedicineSerializer

class AssignmentViewSet(viewsets.ModelViewSet):
    queryset = Assignment.objects.all()
    serializer_class = AssignmentSerializer

    def create(self, request, *args, **kwargs):
        # Custom create to handle patient_id/medicine_id mapping if needed
        return super().create(request, *args, **kwargs)

class SystemStatusView(views.APIView):
    def get(self, request):
        state_machine = hardware.state_machine
        medicine_controller = hardware.medicine_controller
        
        status = state_machine.get_state()
        status.update({
            "wheelAngle": medicine_controller.current_angle,
            "isDoorOpen": medicine_controller.is_door_open,
            "recognizedPatientName": state_machine.state_data.get("last_recognized_patient")
        })
        return Response(status)

class EmergencyStopView(views.APIView):
    def post(self, request):
        hardware.state_machine.set_error("Emergency stop activated")
        hardware.medicine_controller.close_door()
        return Response({"success": True})

class WheelRotateView(views.APIView):
    def post(self, request):
        angle = request.data.get("angle")
        if angle is not None:
            hardware.medicine_controller.rotate_to_angle(angle)
            return Response({"success": True})
        return Response({"error": "Angle required"}, status=400)

class DoorControlView(views.APIView):
    def post(self, request):
        open_door = request.data.get("open")
        ctrl = hardware.medicine_controller
        if open_door:
            ctrl.open_door()
        else:
            ctrl.close_door()
        return Response({"success": True})

class CaptureFacesView(views.APIView):
    def post(self, request, pk):
        success = hardware.state_machine.transition_to(RobotMode.TRAINING_CAPTURE, {
            "patient_id": pk,
            "captured_count": 0,
            "stability_counter": 0,
            "last_capture_time": 0
        })
        if success:
            return Response({"success": True, "message": "Capture started"})
        return Response({"error": "Cannot start capture"}, status=400)

class TrainModelView(views.APIView):
    def post(self, request):
        success = hardware.face_recognizer.train()
        return Response({"success": success})
