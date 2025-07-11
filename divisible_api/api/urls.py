from django.urls import path
from . import views

urlpatterns = [
    path('divisible/<int:number>/', views.DivisibleView.as_view(), name='divisible'),
    path('list/<int:number>/', views.PrimeListView.as_view(), name='list'),
]