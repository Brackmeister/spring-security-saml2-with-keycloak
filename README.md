# Spring security with Keycloak and SAML 2.0 example

## Initial setup

### Keycloak

#### Starting the server
We use Docker to run Keycloak, so make sure you're able to use `docker compose` on your system.

To start keycloak, execute

```
docker compose up -d
```

Then check the logs to see when it's ready

```
docker logs keycloak_saml2
```

As soon as you see "Running the server in development mode. DO NOT use this configuration in production" you can start using keycloak.

The admin UI is available at http://localhost:8104/admin/master/console/ with username "admin" and password "admin".

#### Configuring Keycloak

We use Terraform to configure Keycloak, make sure it's installed on your system.

Once the Keycloak server is running and ready, execute

```
cd terraform
terraform init
terraform apply 
```

This will create a realm "samltest" and a user named "user" with password "user".

Direct admin link to the realm is http://localhost:8104/admin/master/console/#/samltest

### Spring Boot App

#### Store Keycloak SAML meta data in app resources

Open http://localhost:8104/realms/samltest/protocol/saml/descriptor and save it as "xml only" to the app resources
overwriting the existing `metadata-idp-localkeycloak.xml` file. 

#### Generate app key and certificate to sign SAML requests

The `local.key` and `local.crt` commited to this repo expire on 2025-10-31.

To generate a new key plus certificate, execute

```
cd src/main/resources
openssl req -newkey rsa:2048 -nodes -keyout local.key -x509 -days 365 -out local.crt
```

If you like, you can add meaningful data when prompted by openssl, but it's also ok to just take the defaults.

When you have generated a fresh key + certificate you then have to `terraform apply`
to update the certificate in Keycloak.

#### Run the app

Run the app via your IDE of choice or execute

```
mvnw spring-boot:run
```

## Trying it all out

### Initiate app login

Open the Spring Boot app at http://localhost:8080/

As you are not authenticated yet, this will redirect you to http://localhost:8080/saml2/authenticate/localkeycloak
where "localkeycloak" is the name we use for our IDP in line 6 of `application.yml`.

The app properties also point to the SAML 2.0 Identity Provider Metadata of the "samltest" realm.
Those are stored in `metadata-idp-localkeycloak.xml` (as described in the [Setup](#Store-Keycloak-SAML-meta-data-in-app-resources)).
That's how Spring Security knows where the SAML endpoint of the IDP is.

### Login at Keycloak

Now the app redirects to Keycloak at http://localhost:8104/realms/samltest/protocol/saml
(the `SingleSignOnService` URL for the `HTTP-POST` binding from `metadata-idp-localkeycloak.xml`) 
with the following payload (parameter `SAMLRequest` with `Content-Type: application/x-www-form-urlencoded`)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<saml2p:AuthnRequest xmlns:saml2p="urn:oasis:names:tc:SAML:2.0:protocol"
                     AssertionConsumerServiceURL="http://localhost:8080/login/saml2/sso/localkeycloak"
                     Destination="http://localhost:8104/realms/samltest/protocol/saml" ForceAuthn="false"
                     ID="ARQf555939-d60c-4ac0-be2b-b50c283bd00a" IsPassive="false"
                     IssueInstant="2024-10-31T14:17:14.095Z"
                     ProtocolBinding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST" Version="2.0">
    <saml2:Issuer xmlns:saml2="urn:oasis:names:tc:SAML:2.0:assertion">
        http://localhost:8080/saml2/service-provider-metadata/localkeycloak
    </saml2:Issuer>
    <ds:Signature xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
        <ds:SignedInfo>
            <ds:CanonicalizationMethod Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/>
            <ds:SignatureMethod Algorithm="http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"/>
            <ds:Reference URI="#ARQf555939-d60c-4ac0-be2b-b50c283bd00a">
                <ds:Transforms>
                    <ds:Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature"/>
                    <ds:Transform Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/>
                </ds:Transforms>
                <ds:DigestMethod Algorithm="http://www.w3.org/2001/04/xmlenc#sha256"/>
                <ds:DigestValue>u0FhrIo+fpk0UrHw/wWieUyoQpsFZsQlNYh/BQrSnI0=</ds:DigestValue>
            </ds:Reference>
        </ds:SignedInfo>
        <ds:SignatureValue>
            h+5UTVQSfiZRbG71el5si9h3UDbKobt1haD5Qmb+1KIPQxNdrTd5JqRwNxlp04zw0VwlvpfJ7a9q&#13;
            43dAklYXst8TLTRXAJ3Zk5csLVKUiQcry99wYM177WopVcoxOIKJ2A1QgrHy2CjzeHv4me8b6zJg&#13;
            a/13gOemQsRq8LyRWVOo5g8DpOIDPMNU1tgiA5dV4vY+BdfEmO0rM1IeYOSYHzavslK3ohXC+vcZ&#13;
            BcmorQhtUwsaNQre/JWYKAC7h38jZJRwzOL6s7dohNxVqZrhKx/4BsJyeLlgI1bGF8FipKbkA4zB&#13;
            YP12zf5syhn/ZTckIPryGI17iM0hqXOR+9HvrA==
        </ds:SignatureValue>
        <ds:KeyInfo>
            <ds:X509Data>
                <ds:X509Certificate>MIIDazCCAlOgAwIBAgIUfA8n4+F+8CjTCfq7hEDeGW3cwMswDQYJKoZIhvcNAQELBQAwRTELMAkG
                    A1UEBhMCQVUxEzARBgNVBAgMClNvbWUtU3RhdGUxITAfBgNVBAoMGEludGVybmV0IFdpZGdpdHMg
                    UHR5IEx0ZDAeFw0yNDEwMzExMzMzNTBaFw0yNTEwMzExMzMzNTBaMEUxCzAJBgNVBAYTAkFVMRMw
                    EQYDVQQIDApTb21lLVN0YXRlMSEwHwYDVQQKDBhJbnRlcm5ldCBXaWRnaXRzIFB0eSBMdGQwggEi
                    MA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDWoFKid8yzBC0v2vss6L0sOrjFGOLyvb35Kp/O
                    PNV71fZ4jsAAz+SNShws1mrEDWXVy7xKUwDZs8UPo9ZecBYtm8lMdHwwDAha5OWmhLubepghA3yB
                    YWRiOe0S6T0sS6k0nzktyK7pHWj//0ysbwCinLKTR0u+NjQ+Nr9BYQoHkAaHJA85xeodNl2c8hGv
                    dn8lMHOhOEmxQC1BxtOCvKDGEOBpijxldi5JWZnXbPnwHYqUSU4/MQ7leAktQg2BXSrCiTnZMQm/
                    EFPDVAdjDMhDom2ahF4AJ0KoTl75+SFPto1ixs9pXGyYFjjfSThwoxyB1jO4yp7v3UGZyss5jQE5
                    AgMBAAGjUzBRMB0GA1UdDgQWBBSQG6PuBNNweNfPxARyAe+8RfPbVDAfBgNVHSMEGDAWgBSQG6Pu
                    BNNweNfPxARyAe+8RfPbVDAPBgNVHRMBAf8EBTADAQH/MA0GCSqGSIb3DQEBCwUAA4IBAQCARIRj
                    q2Kb2WZUwKNDw0D8Mx7JPpP0lBI4d/GlceIUFvrir8f41D7M1SF/AhDNGA2ZvFyukTCSKCQM9RDd
                    pXa1gHlxxRgCxWuTGQF5BAIjZmy8dwVVSCqNiHRFWfu0IA+P8Zs3kpRTN4StfeAsFv3grlSreqGD
                    fUpBUAEKHiVyPyA/IhrQEdvaKS8bQHG/AhrY4eL9tjPAzcbnnvwm6JaTFtfiJYnuMlVJ654B2Jcl
                    zzP5y68By1SclepsFhtXLq9OERV79e5q8EKZyfsXRRa8hjniGpQjkSyT8CIG2PUYwbBXEiuRJfNH
                    42DS/iGaKoIyzI8UdWWrufQFbupUERrU
                </ds:X509Certificate>
            </ds:X509Data>
        </ds:KeyInfo>
    </ds:Signature>
</saml2p:AuthnRequest>
```

The `Issuer` here is `http://localhost:8080/saml2/service-provider-metadata/localkeycloak` which has to match the
client ID in Keycloak (c.f. line 8 in `main.tf`).

Now log is as "user" with "user" as password.

### Auth callback

Keycloak then performs a POST to http://localhost:8080/login/saml2/sso/localkeycloak
(matching the `AssertionConsumerServiceURL` attribute of the `SAMLRequest`)
with the payload parameter `SAMLResponse`


```xml
<samlp:Response xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion"
                Destination="http://localhost:8080/login/saml2/sso/localkeycloak"
                ID="ID_d8c16dc9-b4ad-4984-a6d1-a771a96bbab1" InResponseTo="ARQf555939-d60c-4ac0-be2b-b50c283bd00a"
                IssueInstant="2024-10-31T14:18:07.781Z" Version="2.0">
    <saml:Issuer>http://localhost:8104/realms/samltest</saml:Issuer>
    <dsig:Signature xmlns:dsig="http://www.w3.org/2000/09/xmldsig#">
        <dsig:SignedInfo>
            <dsig:CanonicalizationMethod Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/>
            <dsig:SignatureMethod Algorithm="http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"/>
            <dsig:Reference URI="#ID_d8c16dc9-b4ad-4984-a6d1-a771a96bbab1">
                <dsig:Transforms>
                    <dsig:Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature"/>
                    <dsig:Transform Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/>
                </dsig:Transforms>
                <dsig:DigestMethod Algorithm="http://www.w3.org/2001/04/xmlenc#sha256"/>
                <dsig:DigestValue>dKuAB2UoKG3WFZdwsyRsoLzYjPV+KbQ0mAyugVaPFkQ=</dsig:DigestValue>
            </dsig:Reference>
        </dsig:SignedInfo>
        <dsig:SignatureValue>
            UJDKh+h8S0BFz2OEFbMRqEP9Op2O8GcccRnHRFjjGqvLokjl9o287IlFAVY2se+IGfhmK/lkKLvISuvTPj/Mj5os1vde+6y8Z+FTBvb5TEK/5AfLBvPHcXeLRH39m3e8Iws88QzNr/aSehX2mIHF9frz1jJ24VnB/CdbrRb+F46E4hzlhjvQnS9BXZRaBj6wu0YMlenxuSnYnIXNa7NFU/yyMd27Obff4XjcXdP2/lc59KQXf8Pvqg3scTRlmjV2gNPFPE/pJBlil0wpATr9/QOe58nhnuS7ez2JdJAH1VVZaYjQeskc3SwQJKbIMA94cMbRhWMgO1GFIPrLKOXWrw==
        </dsig:SignatureValue>
        <dsig:KeyInfo>
            <dsig:KeyName>3OByVf4kffynX2b87OtqBmt9RUbiO2AFI06T02-evuE</dsig:KeyName>
            <dsig:X509Data>
                <dsig:X509Certificate>
                    MIICnzCCAYcCBgGS4sVtYDANBgkqhkiG9w0BAQsFADATMREwDwYDVQQDDAhzYW1sdGVzdDAeFw0yNDEwMzExMzI5MDJaFw0zNDEwMzExMzMwNDJaMBMxETAPBgNVBAMMCHNhbWx0ZXN0MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEArogFhfbXd3pju9eigh6JSvrX5z5Y7mkcZh+Wg9P+X3txmkx8ShNgbx3yIs6c45F5cw67JI8Yums9zsDZTExAnDUFZVtb9RfDrwkpUWPXRBbr3VhSjZImt8+utaoooCGXPTOgoy5ImCfimPRMB+EXS5bYRaNDk+PRhaVjdWuGJWMF5Vh+CKfbYJoNI6iuVbB4S/TwrUeDWixyEqXIlK0rrO68hIcKen0LGXIJNYJ7AJEY+perNezg2SFINHOxGRFH4lk1N5CrMfH4EoPednuiQ3SJ6kKmVm1MUvnTpuzMKn4yHJ7GNIfNIGWTNYMpuTS8TP5hnu5RnGJuVf1M9HMc0QIDAQABMA0GCSqGSIb3DQEBCwUAA4IBAQCajua2cBaRxWI2L+PNJXptnHFFvyAdKhslSrUN+ULEPwNt4MvsvJlkcIU6EfpE7PnAUbGmIrCcG14j1vpTFPf+A74jzogGGuSBx+zRLtwezBsA5ABxQIf6XduXjvKrbKmv4Yqp6u2F1jOte66D3S/Q1znfDdTv1mWBLW8R1y2i2C4X5bfEkMKYT2pWzrNTweUc4WqfrQpXkQW7ACQQkZpOAWBCETgNL9bpuBEw366VmN/lkGrTldUYQoY1NaGBbg25dAh3LOZE1XsCbyJ+dfh5t8PMPplMVhDC6DK5D2wPa4ZPAV9Q/Gaq7ew/eLx6tqAv852oqr0Qiz9RKIhlDKzj
                </dsig:X509Certificate>
            </dsig:X509Data>
        </dsig:KeyInfo>
    </dsig:Signature>
    <samlp:Status>
        <samlp:StatusCode Value="urn:oasis:names:tc:SAML:2.0:status:Success"/>
    </samlp:Status>
    <saml:Assertion xmlns="urn:oasis:names:tc:SAML:2.0:assertion" ID="ID_2ec20571-3035-4dc8-84e2-bf7c5f5ea8b8"
                    IssueInstant="2024-10-31T14:18:07.780Z" Version="2.0">
        <saml:Issuer>http://localhost:8104/realms/samltest</saml:Issuer>
        <saml:Subject>
            <saml:NameID Format="urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress">user@example.com</saml:NameID>
            <saml:SubjectConfirmation Method="urn:oasis:names:tc:SAML:2.0:cm:bearer">
                <saml:SubjectConfirmationData InResponseTo="ARQf555939-d60c-4ac0-be2b-b50c283bd00a"
                                              NotOnOrAfter="2024-10-31T14:23:05.780Z"
                                              Recipient="http://localhost:8080/login/saml2/sso/localkeycloak"/>
            </saml:SubjectConfirmation>
        </saml:Subject>
        <saml:Conditions NotBefore="2024-10-31T14:18:05.780Z" NotOnOrAfter="2024-10-31T14:19:05.780Z">
            <saml:AudienceRestriction>
                <saml:Audience>http://localhost:8080/saml2/service-provider-metadata/localkeycloak</saml:Audience>
            </saml:AudienceRestriction>
        </saml:Conditions>
        <saml:AuthnStatement AuthnInstant="2024-10-31T14:18:07.781Z"
                             SessionIndex="76b133c3-5d0d-4768-8eeb-0522b846afc1::6e682540-c68a-41ab-9c87-fd21c28c28db"
                             SessionNotOnOrAfter="2024-11-01T00:18:07.781Z">
            <saml:AuthnContext>
                <saml:AuthnContextClassRef>urn:oasis:names:tc:SAML:2.0:ac:classes:unspecified
                </saml:AuthnContextClassRef>
            </saml:AuthnContext>
        </saml:AuthnStatement>
        <saml:AttributeStatement>
            <saml:Attribute FriendlyName="email" Name="urn:oid:1.2.840.113549.1.9.1"
                            NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:uri">
                <saml:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema"
                                     xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">
                    user@example.com
                </saml:AttributeValue>
            </saml:Attribute>
            <saml:Attribute FriendlyName="givenName" Name="urn:oid:2.5.4.42"
                            NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:uri">
                <saml:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema"
                                     xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">John
                </saml:AttributeValue>
            </saml:Attribute>
            <saml:Attribute FriendlyName="surname" Name="urn:oid:2.5.4.4"
                            NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:uri">
                <saml:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema"
                                     xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">Doe
                </saml:AttributeValue>
            </saml:Attribute>
            <saml:Attribute Name="Role" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic">
                <saml:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema"
                                     xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">
                    offline_access
                </saml:AttributeValue>
            </saml:Attribute>
            <saml:Attribute Name="Role" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic">
                <saml:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema"
                                     xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">
                    manage-account
                </saml:AttributeValue>
            </saml:Attribute>
            <saml:Attribute Name="Role" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic">
                <saml:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema"
                                     xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">
                    view-profile
                </saml:AttributeValue>
            </saml:Attribute>
            <saml:Attribute Name="Role" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic">
                <saml:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema"
                                     xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">
                    uma_authorization
                </saml:AttributeValue>
            </saml:Attribute>
            <saml:Attribute Name="Role" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic">
                <saml:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema"
                                     xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">
                    default-roles-samltest
                </saml:AttributeValue>
            </saml:Attribute>
            <saml:Attribute Name="Role" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic">
                <saml:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema"
                                     xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">
                    manage-account-links
                </saml:AttributeValue>
            </saml:Attribute>
        </saml:AttributeStatement>
    </saml:Assertion>
</samlp:Response>
```

The realm roles are in the default scope for SAML clients in Keycloak.
The additional `email`, `givenName` and `surname` attributes have been explicitly added
via user attribute mappers (cf. line 20+ in `main.tf`).

And now that we are successfully logged in we are welcomed to the app on http://localhost:8080/?continue

### Initiate app logout

Clicking the "Logout" button will take you to http://localhost:8080/logout

### Logout at Keycloak

The app redirects you to http://localhost:8104/realms/samltest/protocol/saml
(the `SingleLogoutService` URL for the `HTTP-POST` binding from `metadata-idp-localkeycloak.xml`)
with the `SAMLRequest` payload

```xml
<?xml version="1.0" encoding="UTF-8"?>
<saml2p:LogoutRequest xmlns:saml2p="urn:oasis:names:tc:SAML:2.0:protocol"
                      Destination="http://localhost:8104/realms/samltest/protocol/saml"
                      ID="LRd755932a-465c-4331-b4ea-bf00119a1794" IssueInstant="2024-10-31T14:28:20.514Z" Version="2.0">
    <saml2:Issuer xmlns:saml2="urn:oasis:names:tc:SAML:2.0:assertion">
        http://localhost:8080/saml2/service-provider-metadata/localkeycloak
    </saml2:Issuer>
    <ds:Signature xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
        <ds:SignedInfo>
            <ds:CanonicalizationMethod Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/>
            <ds:SignatureMethod Algorithm="http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"/>
            <ds:Reference URI="#LRd755932a-465c-4331-b4ea-bf00119a1794">
                <ds:Transforms>
                    <ds:Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature"/>
                    <ds:Transform Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/>
                </ds:Transforms>
                <ds:DigestMethod Algorithm="http://www.w3.org/2001/04/xmlenc#sha256"/>
                <ds:DigestValue>f3gi4ZqoFKH0gQVvoUo2i6klx52jx6xx4s3FCNSctKc=</ds:DigestValue>
            </ds:Reference>
        </ds:SignedInfo>
        <ds:SignatureValue>
            rdufY2EDC+6HgyimVJ3Yk7OlbU4VqxudFGovfyedmvoxcWvyWxznrSG3FY/T5zHICQY/rKXDgsCc&#13;
            UbHUHmksDKFGjm1RskdgqTA+37HiJU7vaYjhN5Dg8lhRZ7L6as6/JIS807FmRNvXjti9BQQf1MEi&#13;
            fmxOP0nknINYdTwSYnWdYnniP0AxvLUyGHE9k1rkNPI5ngfFGVh4BTcXnCp8S0qkDCr1Z7Jd20en&#13;
            KCLALtxzg4O4FHDrgU087xE0cOB/jr9fG390CLnqSsRfVtqlsICtXjuHxK1O3gfn6QhTzPkH2D4S&#13;
            ZH/RDz25RKUtLMWCDvTRKgRecWvxbe8HbSrqew==
        </ds:SignatureValue>
        <ds:KeyInfo>
            <ds:X509Data>
                <ds:X509Certificate>MIIDazCCAlOgAwIBAgIUfA8n4+F+8CjTCfq7hEDeGW3cwMswDQYJKoZIhvcNAQELBQAwRTELMAkG
                    A1UEBhMCQVUxEzARBgNVBAgMClNvbWUtU3RhdGUxITAfBgNVBAoMGEludGVybmV0IFdpZGdpdHMg
                    UHR5IEx0ZDAeFw0yNDEwMzExMzMzNTBaFw0yNTEwMzExMzMzNTBaMEUxCzAJBgNVBAYTAkFVMRMw
                    EQYDVQQIDApTb21lLVN0YXRlMSEwHwYDVQQKDBhJbnRlcm5ldCBXaWRnaXRzIFB0eSBMdGQwggEi
                    MA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDWoFKid8yzBC0v2vss6L0sOrjFGOLyvb35Kp/O
                    PNV71fZ4jsAAz+SNShws1mrEDWXVy7xKUwDZs8UPo9ZecBYtm8lMdHwwDAha5OWmhLubepghA3yB
                    YWRiOe0S6T0sS6k0nzktyK7pHWj//0ysbwCinLKTR0u+NjQ+Nr9BYQoHkAaHJA85xeodNl2c8hGv
                    dn8lMHOhOEmxQC1BxtOCvKDGEOBpijxldi5JWZnXbPnwHYqUSU4/MQ7leAktQg2BXSrCiTnZMQm/
                    EFPDVAdjDMhDom2ahF4AJ0KoTl75+SFPto1ixs9pXGyYFjjfSThwoxyB1jO4yp7v3UGZyss5jQE5
                    AgMBAAGjUzBRMB0GA1UdDgQWBBSQG6PuBNNweNfPxARyAe+8RfPbVDAfBgNVHSMEGDAWgBSQG6Pu
                    BNNweNfPxARyAe+8RfPbVDAPBgNVHRMBAf8EBTADAQH/MA0GCSqGSIb3DQEBCwUAA4IBAQCARIRj
                    q2Kb2WZUwKNDw0D8Mx7JPpP0lBI4d/GlceIUFvrir8f41D7M1SF/AhDNGA2ZvFyukTCSKCQM9RDd
                    pXa1gHlxxRgCxWuTGQF5BAIjZmy8dwVVSCqNiHRFWfu0IA+P8Zs3kpRTN4StfeAsFv3grlSreqGD
                    fUpBUAEKHiVyPyA/IhrQEdvaKS8bQHG/AhrY4eL9tjPAzcbnnvwm6JaTFtfiJYnuMlVJ654B2Jcl
                    zzP5y68By1SclepsFhtXLq9OERV79e5q8EKZyfsXRRa8hjniGpQjkSyT8CIG2PUYwbBXEiuRJfNH
                    42DS/iGaKoIyzI8UdWWrufQFbupUERrU
                </ds:X509Certificate>
            </ds:X509Data>
        </ds:KeyInfo>
    </ds:Signature>
    <saml2:NameID xmlns:saml2="urn:oasis:names:tc:SAML:2.0:assertion">user@example.com</saml2:NameID>
    <saml2p:SessionIndex>76b133c3-5d0d-4768-8eeb-0522b846afc1::6e682540-c68a-41ab-9c87-fd21c28c28db
    </saml2p:SessionIndex>
</saml2p:LogoutRequest>
```

Logout at Keycloak happens without additional user interaction.

### Logout callback

After logout Keycloak redirects back via POST to http://localhost:8080/logout/saml2/slo (cf. line 13 of `application.yml`)
which was set as `logout_service_post_binding_url` of the client in Keycloak (cf. line 16 of `main.tf`).

The app then redirects to the logout page at http://localhost:8080/login?logout

## Docs

This project was inspired by the following resources:

https://www.baeldung.com/spring-security-saml

https://openvpn.net/as-docs/tutorials/saml-keycloak.html

https://docs.mattermost.com/onboard/sso-saml-keycloak.html

https://registry.terraform.io/providers/mrparkers/keycloak/latest/docs
