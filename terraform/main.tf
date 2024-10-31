resource "keycloak_realm" "realm" {
  realm   = "samltest"
  enabled = true
}

resource "keycloak_saml_client" "saml_client" {
  realm_id  = keycloak_realm.realm.id
  client_id = "http://localhost:8080/saml2/service-provider-metadata/localkeycloak"
  name      = "http://localhost:8080/saml2/service-provider-metadata/localkeycloak"

  valid_redirect_uris = [
    "http://localhost:8080/login/saml2/sso/localkeycloak"
  ]

  name_id_format                  = "email"
  logout_service_post_binding_url = "http://localhost:8080/logout/saml2/slo"
  signing_certificate             = file("../src/main/resources/local.crt")
}

resource "keycloak_saml_user_attribute_protocol_mapper" "x500_email" {
  realm_id      = keycloak_realm.realm.id
  client_id     = keycloak_saml_client.saml_client.id
  name          = "X500 email"
  friendly_name = "email"

  user_attribute             = "email"
  saml_attribute_name        = "urn:oid:1.2.840.113549.1.9.1"
  saml_attribute_name_format = "URI Reference"
}

resource "keycloak_saml_user_attribute_protocol_mapper" "x500_given_name" {
  realm_id      = keycloak_realm.realm.id
  client_id     = keycloak_saml_client.saml_client.id
  name          = "X500 givenName"
  friendly_name = "givenName"

  user_attribute             = "firstName"
  saml_attribute_name        = "urn:oid:2.5.4.42"
  saml_attribute_name_format = "URI Reference"
}

resource "keycloak_saml_user_attribute_protocol_mapper" "x500_last_name" {
  realm_id      = keycloak_realm.realm.id
  client_id     = keycloak_saml_client.saml_client.id
  name          = "X500 surname"
  friendly_name = "surname"

  user_attribute             = "lastName"
  saml_attribute_name        = "urn:oid:2.5.4.4"
  saml_attribute_name_format = "URI Reference"
}

resource "keycloak_user" "user" {
  realm_id = keycloak_realm.realm.id
  username = "user"
  enabled  = true

  email      = "user@example.com"
  first_name = "John"
  last_name  = "Doe"

  initial_password {
    value     = "user"
    temporary = false
  }
}
