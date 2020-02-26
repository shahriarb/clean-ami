#!/usr/bin/ruby
require 'json'

if ARGV.length < 1
  puts "need filter as input"
  exit(1)
end
filter = ARGV[0]
puts "Finding the images base on filter#{filter}"
raw_result = `aws ec2 describe-images --filter Name=name,Values=#{filter} --query  'Images[*].{ID:ImageId, Name:Name}'`

result_amis = JSON.parse(raw_result)

puts "Result:"
puts result_amis
puts "-----"
puts "Found #{result_amis.length} AMI with #{filter} filter"
puts "-----\n\n"
puts "Checking servers for images"

result = []
result_amis.each do |ami|
    ami_id = ami['ID']
    puts "checking instances for #{ami_id}"
    instances_raw = `aws ec2 describe-instances --filter Name=image-id,Values=#{ami_id}`
    instances = JSON.parse(instances_raw)
    instances_detail = []
    instances["Reservations"].each do |reservation|
      reservation["Instances"].each do  |instance|
        puts instance['Tags'].find {|tag| tag['Key'] == "Name"}["Value"]
        instances_detail << {"ID": instance["InstanceId"],  "Name": instance['Tags'].find {|tag| tag['Key'] == "Name"}["Value"]}
      end
    end
    result << {"ID": ami_id, "Name": ami["Name"], "Instances": instances_detail}
    puts "--------"
end


puts "\n\n\nAMI(s) with runing instances:"
counter = 0
result.select{|r| r[:Instances].length > 0}.each do |res|
  puts "AmiID: #{res[:ID]}\nName:#{res[:Name]}\nInstances:"
  puts "--"
  res[:Instances].each do |instance|
    puts "InstanceID:#{instance[:ID]}\tName:#{instance[:Name]}"
  end
  counter += 1
  puts "==================================="
end
puts "Total: #{counter}\n\n\n"


puts "\n\n\nAMI(s) with no instance:"
counter = 0
result.select{|r| r[:Instances].length == 0}.each do |res|
  puts "AmiID: #{res[:ID]}\tName:#{res[:Name]}\n"
  counter += 1
end
puts "Total: #{counter}\n\n\n"
