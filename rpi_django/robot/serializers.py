from rest_framework import serializers
from .models import Patient, Medicine, Assignment

class PatientSerializer(serializers.ModelSerializer):
    class Meta:
        model = Patient
        fields = ['id', 'name', 'is_trained', 'created_at']

class MedicineSerializer(serializers.ModelSerializer):
    class Meta:
        model = Medicine
        fields = ['id', 'name', 'angle', 'slot_index', 'created_at']

class AssignmentSerializer(serializers.ModelSerializer):
    patient_name = serializers.ReadOnlyField(source='patient.name')
    medicine_name = serializers.ReadOnlyField(source='medicine.name')
    medicine_angle = serializers.ReadOnlyField(source='medicine.angle')

    class Meta:
        model = Assignment
        fields = ['id', 'patient', 'medicine', 'patient_name', 'medicine_name', 'medicine_angle', 'created_at']
