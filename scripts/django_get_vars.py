from django.conf import settings

#CELERY_BROKER_URL
#BROKER_URL
#CELERY_BROKER_URL = 'redis://redis:6379/0'
#BROKER_URL = 'amqp://vcz:vczap@' + API_TCP_SERVER_HOST + ':5672//'


dir_settings = dir(settings)
celery_vars = [
	'CELERY_BROKER_URL',
	'BROKER_URL',
]

BROKER_URL = ''
BROKER_PORT = '0'
BROKER_PROTOCOL = ''

for item in celery_vars:
	if item in dir_settings:
		BROKER_URL = eval("settings.{0}".format(item))
		break


try:
	protocol, addr = BROKER_URL.split("://")
	BROKER_PROTOCOL = protocol.lower()
except:
	protocol = ''
	addr = ''

if ':' in addr:
	addr_s = addr.split(":")
	port = addr_s[-1].split("/")[0]
	try:
		BROKER_PORT = str(int(port))
	except:
		pass

output = [
	"{0}='{1}'\n".format('STATIC_URL', settings.STATIC_URL),
	"{0}='{1}'\n".format('STATIC_ROOT', settings.STATIC_ROOT),
	"{0}='{1}'\n".format('BROKER_URL', BROKER_URL),
	"{0}='{1}'\n".format('BROKER_PROTOCOL', BROKER_PROTOCOL),
	"{0}={1}\n".format('BROKER_PORT', BROKER_PORT),
]	

with open("/src/django_env", "w") as f:
	for o in output:
		f.write(o)



