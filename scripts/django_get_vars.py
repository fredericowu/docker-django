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
BROKER_PORT = ''

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
	

print("export {0}='{1}'".format('STATIC_URL', settings.STATIC_URL))
print("export {0}='{1}'".format('STATIC_ROOT', settings.STATIC_ROOT))
print("export {0}='{1}'".format('BROKER_URL', BROKER_URL))
print("export {0}='{1}'".format('BROKER_PROTOCOL', BROKER_PROTOCOL))
print("export {0}={1}".format('BROKER_PORT', BROKER_PORT))

