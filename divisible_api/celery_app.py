from __future__ import absolute_import, unicode_literals
import os
import sys
from pathlib import Path
from celery import Celery

# set the default Django settings module for the 'celery' program.
sys.path.append(str(Path(__file__).resolve().parent.parent))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'divisible_api.divisible_api.settings')

app = Celery('divisible_api')

# Using a string here means the worker doesn't have to serialize
# the configuration object to child processes.
# - namespace='CELERY' means all celery-related configuration keys
#   should have a `CELERY_` prefix.
app.config_from_object('django.conf:settings', namespace='CELERY')

# Load task modules from all registered Django app configs.
app.autodiscover_tasks()
