### 0.4.7
* Add `set_tenant_name` and `set_endpoint_id` setters 

### 0.4.6
* Lessen `gen_smtp` version dependency from "~> 1.2.0" to "~> 1.2"

### 0.4.5
* Message is sent using the Simple content type if message has just headers.
* Raw content generation is fixed and refactored
* Header encoding improvements

### 0.4.4
Minor improvements

### 0.4.3
`ex_aws` version set to `~> 2.4`

### 0.4.2
`eiconv` is a test env dependency

### 0.4.1
Fix bug related to local part being puny code encoded

### 0.4.0
Switch to gen_smtp's renderer for raw emails
