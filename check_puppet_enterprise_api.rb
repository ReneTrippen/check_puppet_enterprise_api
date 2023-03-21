#!/opt/puppetlabs/puppet/bin/ruby

require 'net/http'
require 'uri'
require 'json'
require 'optparse'
require 'openssl'

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

  opts.on("-c CERTIFICATE", "--certificate CERTIFICATE", "Path to host certificate file") do |certificate|
    options[:certificate] = certificate
  end

  opts.on("-k KEY", "--key KEY", "Path to host key file") do |key|
    options[:key] = key
  end

  opts.on("-a CA_CERT", "--ca-cert CA_CERT", "Path to CA certificate file") do |ca_cert|
    options[:ca_cert] = ca_cert
  end
end.parse!
# Check that at least one service name and port is provided
if options[:service_ports].empty?
  puts "Error: service and port are required"
  exit UNKNOWN
end

# Check that certificate, key, and CA cert are provided
if options[:certificate].nil? || options[:key].nil? || options[:ca_cert].nil?
  puts "Error: certificate, key, and CA cert are required"
  exit UNKNOWN
end

# Load the certificate and key files
certificate = OpenSSL::X509::Certificate.new(File.read(options[:certificate]))
key = OpenSSL::PKey::RSA.new(File.read(options[:key]))

# Load the CA cert file
ca_cert = OpenSSL::X509::Certificate.new(File.read(options[:ca_cert]))

# Create an SSL context with the certificate, key, and CA cert
ssl_context = OpenSSL::SSL::SSLContext.new
ssl_context.cert = certificate
ssl_context.key = key
ssl_context.verify_mode = OpenSSL::SSL::VERIFY_PEER
ssl_context.cert_store = OpenSSL::X509::Store.new
ssl_context.cert_store.add_cert(ca_cert)

# Check the status of each service and print the service name and state
options[:service_ports].each do |service_port|
  service_name = service_port[:service_name]
  port_number = service_port[:port_number]
  api_url = URI.parse("https://localhost:#{port_number}/status/v1/services?service=#{service_name}")

  # Set up the HTTPS connection with the SSL context
  https = Net::HTTP.new(api_url.host, api_url.port)
  https.use_ssl = true
  https.verify_mode = OpenSSL::SSL::VERIFY_PEER
  https.cert = certificate
  https.key = key
  https.ca_file = options[:ca_cert]
  https.ssl_context = ssl_context

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

