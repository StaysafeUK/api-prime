from django.urls import path
from . import views

urlpatterns = [
    path('divisible/<int:number>/', views.DivisibleView.as_view(), name='divisible'),
]