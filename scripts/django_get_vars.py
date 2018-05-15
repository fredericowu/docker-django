from django.conf import settings

print("{0}='{1}'".format( 'STATIC_URL', settings.STATIC_URL ) )
print("{0}='{1}'".format( 'STATIC_ROOT', settings.STATIC_ROOT ) )
