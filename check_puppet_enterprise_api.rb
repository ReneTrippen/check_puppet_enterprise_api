#!/opt/puppetlabs/puppet/bin/ruby

require 'net/http'
require 'uri'
require 'json'
require 'optparse'

# Define default values for options
options = { service_ports: [] }

# Define the keys to retrieve for the status information
status_information_keys = ['state', 'status', 'active_alerts']

# Define the Icinga exit codes
OK = 0
WARNING = 1
CRITICAL = 2
UNKNOWN = 3

# Parse the command line options
OptionParser.new do |opts|
  opts.banner = "Usage: ruby script.rb [options]"
  
  opts.on("-s SERVICE_PORT", "--service-port SERVICE_PORT", "Name of the service and port to check (format: SERVICE_NAME:PORT_NUMBER)") do |service_port|
    service_name, port_number = service_port.split(":")
    options[:service_ports] << { service_name: service_name, port_number: port_number.to_i }
  end
  
  opts.on_tail("-h", "--help", "Show this message") do
    puts opts
    exit
  end
end.parse!

# Check that at least one service name and port is provided
if options[:service_ports].empty?
  puts "Error: service and port are required"
  exit UNKNOWN
end

# Check the status of each service and print the service name and state
options[:service_ports].each do |service_port|
  service_name = service_port[:service_name]
  port_number = service_port[:port_number]
  api_url = URI.parse("https://localhost:#{port_number}/status/v1/services?service=#{service_name}")

  # Set up the HTTP connection
  http = Net::HTTP.new(api_url.host, api_url.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE

  # Create the HTTP request
  request = Net::HTTP::Get.new(api_url.path)
  request['Content-Type'] = 'application/json'

  # Send the request and get the response
  begin
    response = http.request(request)
  rescue => e
    puts "Error retrieving data from API for #{service_name}: #{e}"
    next
  end

  # Parse the response body as JSON
  parsed_status = JSON.parse(response.body)

  if parsed_status.key?(service_name)
    case parsed_status[service_name]['state']
    when 'running'
      puts "Service #{service_name} is running"
    when 'failed'
      puts "Service #{service_name} is in a failed state"
      status_information_keys.each do |information_key|
        puts "#{information_key.capitalize}: #{parsed_status[service_name][information_key]}"
      end
      exit CRITICAL
    else
      puts "Unknown service state for #{service_name}: #{parsed_status[service_name]['state']}"
      status_information_keys.each do |information_key|
        puts "#{information_key.capitalize}: #{parsed_status[service_name][information_key]}"
      end
      exit UNKNOWN
    end
  else
    puts "Unknown service: #{service_name}"
    exit UNKNOWN
  end
end

exit OK

