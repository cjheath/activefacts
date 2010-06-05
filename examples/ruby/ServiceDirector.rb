require 'activefacts/api'

module ::ServiceDirector

  class CompanyCode < Char
    value_type :length => 5
  end

  class CredentialNr < SignedInteger
    value_type :length => 32
  end

  class DDMMYYYY < Date
    value_type 
  end

  class DataStoreName < String
    value_type :length => 15
  end

  class EmailAddress < String
    value_type :length => 50
  end

  class HHMMSS < Time
    value_type 
  end

  class HostSystemName < String
    value_type :length => 15
  end

  class IP < String
    value_type :length => 16
  end

  class MDYHMS < AutoTimeStamp
    value_type 
  end

  class MessageData < Blob
    value_type :length => 8000
  end

  class MessageHeader < String
    value_type :length => 30
  end

  class MonitorId < AutoCounter
    value_type 
  end

  class MonitoringApplicationName < String
    value_type :length => 10
  end

  class Name < String
    value_type :length => 15
  end

  class Netmask < String
    value_type :length => 16
  end

  class NetworkNr < SignedInteger
    value_type :length => 32
  end

  class NotificationLevelNr < SignedInteger
    value_type :length => 32
  end

  class NotificationTypeName < String
    value_type :length => 20
  end

  class Password < String
    value_type 
  end

  class Path < String
    value_type :length => 20
  end

  class Port < SignedInteger
    value_type :length => 32
  end

  class ProviderTypeId < SignedInteger
    value_type :length => 20
  end

  class RecurringScheduleId < AutoCounter
    value_type 
  end

  class SatelliteMessageId < UnsignedInteger
    value_type :length => 32
  end

  class Seconds < UnsignedInteger
    value_type :length => 32
  end

  class SerialNumber < String
    value_type :length => 20
  end

  class ServiceType < String
    value_type :length => 15
  end

  class SubscriptionNr < SignedInteger
    value_type :length => 32
  end

  class SwitchId < AutoCounter
    value_type 
  end

  class TransactionNr < UnsignedInteger
    value_type :length => 32
  end

  class TruckPCID < UnsignedInteger
    value_type :length => 32
  end

  class UserName < String
    value_type :length => 20
  end

  class Version < Char
    value_type :length => 5
  end

  class Company
    identified_by :company_code
    one_to_one :company_code, :mandatory => true  # See CompanyCode.company
    maybe :is_client
    maybe :is_vendor
    has_one :operating_name, :class => Name, :mandatory => true  # See Name.all_company_as_operating_name
  end

  class Credential
    identified_by :credential_nr
    one_to_one :credential_nr, :mandatory => true  # See CredentialNr.credential
    has_one :data_store                         # See DataStore.all_credential
    has_one :data_store_service                 # See DataStoreService.all_credential
    has_one :expiration_date, :class => "Date"  # See Date.all_credential_as_expiration_date
    has_one :password, :mandatory => true       # See Password.all_credential
    has_one :user_name, :mandatory => true      # See UserName.all_credential
    has_one :vendor                             # See Vendor.all_credential
  end

  class DataStore
    identified_by :data_store_name
    has_one :client, :mandatory => true         # See Client.all_data_store
    one_to_one :data_store_name, :mandatory => true  # See DataStoreName.data_store
    one_to_one :friendly_name, :class => Name, :mandatory => true  # See Name.data_store_as_friendly_name
    has_one :geocode_file                       # See GeocodeFile.all_data_store
    has_one :heart_beat_truck_pcid, :class => TruckPCID  # See TruckPCID.all_data_store_as_heart_beat_truck_pcid
    one_to_one :internal_credential, :class => Credential, :mandatory => true  # See Credential.data_store_as_internal_credential
    has_one :major_version, :class => Version, :mandatory => true  # See Version.all_data_store_as_major_version
    has_one :minor_version, :class => Version, :mandatory => true  # See Version.all_data_store_as_minor_version
    has_one :primary_host_system, :class => "HostSystem", :mandatory => true  # See HostSystem.all_data_store_as_primary_host_system
    has_one :revision_version, :class => Version, :mandatory => true  # See Version.all_data_store_as_revision_version
    has_one :secondary_host_system, :class => "HostSystem", :mandatory => true  # See HostSystem.all_data_store_as_secondary_host_system
  end

  class Date
    identified_by :ddmmyyyy
    one_to_one :ddmmyyyy, :class => DDMMYYYY, :mandatory => true  # See DDMMYYYY.date
  end

  class DateTime
    identified_by :mdyhms
    one_to_one :mdyhms, :class => MDYHMS, :mandatory => true  # See MDYHMS.date_time
  end

  class Duration
    identified_by :seconds
    one_to_one :seconds, :mandatory => true     # See Seconds.duration
  end

  class GeocodeFile
    identified_by :path
    one_to_one :path, :mandatory => true        # See Path.geocode_file
  end

  class HostSystem
    identified_by :host_system_name
    one_to_one :host_system_name, :mandatory => true  # See HostSystemName.host_system
  end

  class Monitor
    identified_by :monitor_id
    has_one :data_store, :mandatory => true     # See DataStore.all_monitor
    maybe :is_disabled
    one_to_one :monitor_id, :mandatory => true  # See MonitorId.monitor
    has_one :monitoring_application, :mandatory => true  # See MonitoringApplication.all_monitor
  end

  class MonitoringApplication
    identified_by :monitoring_application_name
    one_to_one :monitoring_application_name, :mandatory => true  # See MonitoringApplicationName.monitoring_application
  end

  class Network
    identified_by :network_nr
    has_one :company, :counterpart => :origin_network  # See Company.all_origin_network
    has_one :data_store, :counterpart => :tcp_proxy_network  # See DataStore.all_tcp_proxy_network
    has_one :domain_name, :class => Name        # See Name.all_network_as_domain_name
    one_to_one :ending_ip, :class => IP         # See IP.network_as_ending_ip
    has_one :host_system                        # See HostSystem.all_network
    one_to_one :initial_ip, :class => IP, :mandatory => true  # See IP.network_as_initial_ip
    maybe :is_ip_range
    maybe :is_ip_single
    maybe :is_ip_subnet
    has_one :netmask                            # See Netmask.all_network
    one_to_one :network_nr, :mandatory => true  # See NetworkNr.network
    has_one :private_interface_switch, :class => "Switch", :counterpart => :private_network  # See Switch.all_private_network
    has_one :public_interface_switch, :class => "Switch", :counterpart => :public_network  # See Switch.all_public_network
  end

  class NotificationLevel
    identified_by :notification_level_nr
    has_one :initial_delay_duration, :class => Duration, :mandatory => true  # See Duration.all_notification_level_as_initial_delay_duration
    one_to_one :notification_level_nr, :mandatory => true  # See NotificationLevelNr.notification_level
    has_one :repeat_duration, :class => Duration, :mandatory => true  # See Duration.all_notification_level_as_repeat_duration
  end

  class NotificationType
    identified_by :notification_type_name
    one_to_one :notification_type_name, :mandatory => true  # See NotificationTypeName.notification_type
  end

  class ProviderType
    identified_by :provider_type_id
    one_to_one :provider_type_id, :mandatory => true  # See ProviderTypeId.provider_type
  end

  class RecurringSchedule
    identified_by :recurring_schedule_id
    has_one :duration, :mandatory => true       # See Duration.all_recurring_schedule
    maybe :friday
    has_one :integrating_monitor, :class => Monitor, :counterpart => :integration_exclusion_recurring_schedule  # See Monitor.all_integration_exclusion_recurring_schedule
    maybe :monday
    has_one :monitor, :counterpart => :all_exclusion_recurring_schedule  # See Monitor.all_all_exclusion_recurring_schedule
    one_to_one :recurring_schedule_id, :mandatory => true  # See RecurringScheduleId.recurring_schedule
    maybe :saturday
    has_one :start_time, :class => "Time", :mandatory => true  # See Time.all_recurring_schedule_as_start_time
    maybe :sunday
    maybe :thursday
    maybe :tuesday
    maybe :wednesday
  end

  class SatelliteMessage
    identified_by :satellite_message_id
    has_one :data_store, :mandatory => true     # See DataStore.all_satellite_message
    has_one :group_transaction, :class => "Transaction"  # See Transaction.all_satellite_message_as_group_transaction
    has_one :insertion_date_time, :class => DateTime, :mandatory => true  # See DateTime.all_satellite_message_as_insertion_date_time
    has_one :message_data                       # See MessageData.all_satellite_message
    has_one :message_header                     # See MessageHeader.all_satellite_message
    has_one :provider_type                      # See ProviderType.all_satellite_message
    one_to_one :satellite_message_id, :mandatory => true  # See SatelliteMessageId.satellite_message
    has_one :serial_number, :mandatory => true  # See SerialNumber.all_satellite_message
  end

  class Subscription
    identified_by :subscription_nr
    has_one :beginning_date, :class => Date, :mandatory => true  # See Date.all_subscription_as_beginning_date
    one_to_one :company, :counterpart => :driver_tech_subscription  # See Company.driver_tech_subscription
    has_one :ending_date, :class => Date        # See Date.all_subscription_as_ending_date
    maybe :is_enabled
    one_to_one :subscription_nr, :mandatory => true  # See SubscriptionNr.subscription
  end

  class Switch
    identified_by :switch_id
    one_to_one :data_store, :counterpart => :legacy_switch  # See DataStore.legacy_switch
    maybe :is_backup_messages
    maybe :is_backup_updates
    maybe :is_send_disabled
    maybe :is_test_vectors_enabled
    has_one :major_version, :class => Version, :mandatory => true  # See Version.all_switch_as_major_version
    has_one :minor_version, :class => Version, :mandatory => true  # See Version.all_switch_as_minor_version
    one_to_one :monitoring_port, :class => Port, :mandatory => true  # See Port.switch_as_monitoring_port
    has_one :operating_port, :class => Port, :mandatory => true  # See Port.all_switch_as_operating_port
    has_one :revision_version, :class => Version, :mandatory => true  # See Version.all_switch_as_revision_version
    one_to_one :switch_id, :mandatory => true   # See SwitchId.switch
  end

  class Time
    identified_by :hhmmss
    one_to_one :hhmmss, :class => HHMMSS, :mandatory => true  # See HHMMSS.time
  end

  class Transaction
    identified_by :transaction_nr
    one_to_one :transaction_nr, :mandatory => true  # See TransactionNr.transaction
  end

  class User
    identified_by :user_name
    maybe :is_monitor_notification_disabled
    has_one :primary_email_address, :class => EmailAddress, :mandatory => true  # See EmailAddress.all_user_as_primary_email_address
    has_one :secondary_email_address, :class => EmailAddress  # See EmailAddress.all_user_as_secondary_email_address
    one_to_one :user_name, :mandatory => true   # See UserName.user
  end

  class Vendor < Company
  end

  class Client < Company
    has_one :default_data_store, :class => DataStore  # See DataStore.all_client_as_default_data_store
  end

  class FileHostSystem < HostSystem
    has_one :port, :mandatory => true           # See Port.all_file_host_system
  end

  class HostSystemRunsSwitch
    identified_by :host_system, :switch
    has_one :host_system, :mandatory => true    # See HostSystem.all_host_system_runs_switch
    has_one :switch, :mandatory => true         # See Switch.all_host_system_runs_switch
  end

  class MonitorNotificationType
    identified_by :monitor, :notification_type
    has_one :monitor, :mandatory => true        # See Monitor.all_monitor_notification_type
    has_one :notification_type, :mandatory => true  # See NotificationType.all_monitor_notification_type
    maybe :is_excluded
  end

  class MonitorNotificationUser
    identified_by :monitor_notification_type, :notification_user
    has_one :monitor_notification_type, :mandatory => true  # See MonitorNotificationType.all_monitor_notification_user
    has_one :notification_user, :class => User, :mandatory => true  # See User.all_monitor_notification_user_as_notification_user
    has_one :notification_level, :mandatory => true  # See NotificationLevel.all_monitor_notification_user
  end

  class Service
    identified_by :vendor, :service_type
    has_one :service_type, :mandatory => true   # See ServiceType.all_service
    has_one :vendor, :mandatory => true         # See Vendor.all_service
  end

  class DataStoreFileHostSystem
    identified_by :data_store
    one_to_one :data_store, :mandatory => true  # See DataStore.data_store_file_host_system
    has_one :file_host_system, :mandatory => true  # See FileHostSystem.all_data_store_file_host_system
    one_to_one :internal_credential, :class => Credential, :mandatory => true  # See Credential.data_store_file_host_system_as_internal_credential
  end

  class DataStoreService
    identified_by :service, :data_store
    has_one :data_store, :mandatory => true     # See DataStore.all_data_store_service
    has_one :service, :mandatory => true        # See Service.all_data_store_service
    has_one :client, :mandatory => true         # See Client.all_data_store_service
    one_to_one :subscription, :mandatory => true  # See Subscription.data_store_service
  end

end
