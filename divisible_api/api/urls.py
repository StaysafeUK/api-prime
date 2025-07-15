from django.urls import path, re_path
from . import views

urlpatterns = [
    path('divisible/<int:number>/', views.DivisibleView.as_view(), name='divisible'),
    path('list/<int:number>/', views.PrimeListView.as_view(), name='list'),
    re_path(r'^prime_next/(?P<number>-?\d+)/$', views.NextPrimeView.as_view(), name='prime_next'),
    re_path(r'^prime_prev/(?P<number>-?\d+)/$', views.PreviousPrimeView.as_view(), name='prime_prev'),
    path('all/<int:number>/', views.AllInOneView.as_view(), name='all'),
]
