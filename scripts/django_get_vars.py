from django.conf import settings
import os

def get_broker():
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
	result = {
		'BROKER_URL': BROKER_URL,
		'BROKER_PORT': BROKER_PORT,
		'BROKER_PROTOCOL': BROKER_PROTOCOL,
	}
	return result


def get_database():
	try:
		# TODO: Support many
		db = settings.DATABASES['default']
	except:
		db = {}
	keys = [
		'ENGINE',
		'NAME',
		'USER',
		'HOST',
		'PORT',
		'PASSWORD',
	]
	result = {}
	for key in keys:
		result_key = "DB_{0}".format(key)
		if key in db:
			result[result_key] = db[key]
		else:
			result[result_key] = ''
	result['DB_ENGINE'] = result['DB_ENGINE'].split(".")[-1]
	return result


def format_dict(d):
	result = []
	for k in d:
		result.append("{0}='{1}'\n".format(k, d[k]))
	return result	

defaults = {
	'STATIC_URL': settings.STATIC_URL,
	'STATIC_ROOT': settings.STATIC_ROOT,
	'DJANGO_SETTINGS_MODULE': os.environ.get("DJANGO_SETTINGS_MODULE"),
	'DJANGO_WSGI': os.environ.get("DJANGO_SETTINGS_MODULE").replace("settings", "wsgi"),
}

broker = get_broker()
db = get_database()

output = format_dict(defaults)
output += format_dict(broker)
output += format_dict(db)


with open("/src/django_env", "w") as f:
	for o in output:
		f.write(o)



