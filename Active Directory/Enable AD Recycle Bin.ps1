#Change this domain bellow

$domain = "yourdomain.com"

#---------------------------------------------------------------------------------------------------------------------------------------------------------
#			SCRIPT
#---------------------------------------------------------------------------------------------------------------------------------------------------------
$DN_DOMAIN = "DC="+($domain.Replace(".",",DC="))
Enable-ADOptionalFeature –Identity "CN=Recycle Bin Feature,CN=Optional Features,CN=Directory Service,CN=Windows NT,CN=Services,CN=Configuration,$DN_DOMAIN" –Scope ForestOrConfigurationSet –Target $domain