# Check Puppet Enterprise API Script
This script checks the status of the Puppet Enterprise API endpoints specified by the user. It supports multiple service names and ports as command line arguments.

## Requirements
 * Ruby 2.0 or higher
 * Ruby Gems
   * net/http 
   * json
   * uri
   * optparse

## Usage
Run the script using the following command:

```ruby
ruby check_puppet_enterprise_api.rb -s SERVICE_NAME:PORT_NUMBER [-s SERVICE_NAME:PORT_NUMBER ...]
```

For example, to check the status of the Puppet Server API and PE Console Services, you would run the following command:

```ruby
ruby check_puppet_enterprise_api.rb -s code-manager-service:8140 -s file-sync-storage-service:8140 -s file-sync-client-service:8140 -s master:8140 -s classifier-service:4433 -s activity-service:4433 -s rbac-service:4433
````
The script will check the status of each service and print the service name and state to the console. If any services are in a failed state, additional information about the failure will be printed, and the script will exit with a non-zero status code.



## Command Line Options
The following command line options are supported:

 * -s SERVICE_NAME:PORT_NUMBER, --service-port SERVICE_NAME:PORT_NUMBER: Name of the service and port to check (e.g. code-manager-service:8140). You can specify multiple service names and ports by using this option multiple times.
 * -h, --help: Show the usage message.

## Output
The script outputs the status of each service in the following format:

````
Service SERVICE_NAME is running
````

## Example Output
```
Service code-manager-service is running
Service file-sync-storage-service is running
Service file-sync-client-service is running
Service master is running
Service classifier-service is running
Service activity-service is running
Service rbac-service is running
Service orchestrator-service is running
Service broker-service is running
Service puppetdb-status is running
```

## Icinga Exit Code
This script uses the following Icinga exit codes:

 * 0: OK
 * 1: WARNING
 * 2: CRITICAL
 * 3: UNKNOWN
