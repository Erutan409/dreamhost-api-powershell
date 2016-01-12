# Dreamhost API - PowerShell

The purpose of this code is to allow interfacing with a Dreamhost account via their API.  Once such purpose would be to automatically update DNS entries for ***DNS hosted only*** records for remote hosts that have dynamic IP's.

## Supported API Commands
---
### API Metacommands
- Listing
```
> API-GetCommands -apiKey 6SHU5P2HLDAYECUM


Command                                       Order                                         Arguments                                    OptionalArguments
-------                                       -----                                         ---------                                    -----------------
announcement_list-list_lists                  see_docs                                      see_docs                                     see_docs
announcement_list-list_subscribers            see_docs                                      see_docs                                     see_docs
api-list_accessible_cmds                      {cmd, args, optargs, order}                   {}                                           {}
dns-list_records                              see_docs                                      see_docs                                     see_docs
etc...
```
- Keys
```
> API-GetKeys -apiKey 6SHU5P2HLDAYECUM


Key                                           Functions                                     Comment                                      Created
---                                           ---------                                     -------                                      -------
6SHU5P2HLDAYECUM                              *                                             Admin API                                    2016-01-11 16:43:03
```

### DNS Records
- Listing
```
> DnsRecord-Fetch -apiKey 6SHU5P2HLDAYECUM | Format-Table


Record                               Value                                Type                                Comment                             Editable
------                               -----                                ----                                -------                             --------
groo.com                             208.113.141.116                      A                                                                       No
ssh.album.groo.com                   75.119.200.215                       A                                                                       No
a6.groo.com                          1234:1234:1234:1234:1234:1234:123... AAAA                                test                                Yes
aaaaaa.groo.com                      0000:0000:0000:0000:0000:0000:000... AAAA                                testing!                            Yes
mailboxes.google.groo.com            208.97.187.203                       A                                                                       No
image.groo.com                       d1z8lr53cxmcgi.cloudfront.net.       CNAME                               104::cloudfront                     Yes
etc...
```
- Adding
```
> DnsRecord-Add -apiKey 6SHU5P2HLDAYECUM -record "sub.domain.suffix" -type "A" -value (PublicIP-Fetch)


Are you sure want to add the following record: sub.domain.suffix | A | %CURL_IP%: y

Record successfully added
```
- Removing
```
> DnsRecord-Remove -apiKey 6SHU5P2HLDAYECUM -record "sub.domain.suffix" -type "A" -value "%IP_ADDRESS%"


Are you sure want to remove the following record: sub.domain.suffix | A | %IP_ADDRESS%: y

Record successfully removed
```