from django.db import models

class Patient(models.Model):
    name = models.CharField(max_length=100)
    is_trained = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.name

class Medicine(models.Model):
    name = models.CharField(max_length=100)
    angle = models.FloatField()
    slot_index = models.IntegerField()
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.name} ({self.angle}°)"

class Assignment(models.Model):
    patient = models.ForeignKey(Patient, on_delete=models.CASCADE, related_name='assignments')
    medicine = models.ForeignKey(Medicine, on_delete=models.CASCADE, related_name='assignments')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('patient', 'medicine')

    def __str__(self):
        return f"{self.patient.name} -> {self.medicine.name}"
