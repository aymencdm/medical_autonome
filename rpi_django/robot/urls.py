from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

router = DefaultRouter()
router.register(r'patients', views.PatientViewSet)
router.register(r'medicines', views.MedicineViewSet)
router.register(r'assignments', views.AssignmentViewSet)

urlpatterns = [
    path('', include(router.urls)),
    path('system/status', views.SystemStatusView.as_view(), name='system-status'),
    path('system/emergency_stop', views.EmergencyStopView.as_view(), name='emergency-stop'),
    path('wheel/rotate', views.WheelRotateView.as_view(), name='wheel-rotate'),
    path('wheel/door', views.DoorControlView.as_view(), name='door-control'),
    path('patients/<int:pk>/capture', views.CaptureFacesView.as_view(), name='capture-faces'),
    path('train', views.TrainModelView.as_view(), name='train-model'),
]
