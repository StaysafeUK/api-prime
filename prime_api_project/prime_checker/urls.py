
from django.urls import path
from . import views

urlpatterns = [
    path('is_prime/<int:number>/', views.is_prime_api, name='is_prime_api'),
]
