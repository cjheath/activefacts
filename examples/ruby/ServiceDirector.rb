require 'activefacts/api'

module ServiceDirector

  class Company_Code < FixedLengthText
    value_type :length => 5
  end

  class Credential_Nr < SignedInteger
    value_type :length => 32
  end

  class DDMMYYYY < ::Date
    value_type 
  end

  class DataStore_Name < String
    value_type :length => 15
  end

  class EmailAddress < String
    value_type :length => 50
  end

  class HHMMSS < ::Time
    value_type 
  end

  class HostSystem_Name < String
    value_type :length => 15
  end

  class IP < String
    value_type :length => 16
  end

  class MDYHMS < AutoTimestamp
    value_type 
  end

  class MessageData < VariableLengthRawData
    value_type :length => 8000
  end

  class MessageHeader < String
    value_type :length => 30
  end

  class Monitor_Id < AutoCounter
    value_type 
  end

  class MonitoringApplication_Name < String
    value_type :length => 10
  end

  class Name < String
    value_type :length => 15
  end

  class Netmask < String
    value_type :length => 16
  end

  class Network_Nr < SignedInteger
    value_type :length => 32
  end

  class NotificationLevel_Nr < SignedInteger
    value_type :length => 32
  end

  class NotificationType_Name < String
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

  class ProviderType_Id < SignedSmallInteger
    value_type :length => 20
  end

  class RecurringSchedule_Id < AutoCounter
    value_type 
  end

  class SatalliteMessage_Id < UnsignedInteger
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

  class Subscription_Nr < SignedInteger
    value_type :length => 32
  end

  class Switch_Id < AutoCounter
    value_type 
  end

  class Transaction_Nr < UnsignedInteger
    value_type :length => 32
  end

  class TruckPCID < UnsignedInteger
    value_type :length => 32
  end

  class UserName < String
    value_type :length => 20
  end

  class User_Name < String
    value_type :length => 40
  end

  class Version < FixedLengthText
    value_type :length => 5
  end

  class Company
    identified_by :company_code
    one_to_one :company_code, Company_Code      # See Company_Code.company
    maybe :is_client
    maybe :is_vendor
    has_one :operating_name, Name               # See Name.all_company_as_operating_name
  end

  class Credential
    identified_by :credential_nr
    one_to_one :credential_nr, Credential_Nr    # See Credential_Nr.credential
    has_one :data_store                         # See DataStore.all_credential
    has_one :data_store_service                 # See DataStoreService.all_credential
    has_one :expiration_date, "Date"            # See Date.all_credential_as_expiration_date
    has_one :password                           # See Password.all_credential
    has_one :user_name                          # See UserName.all_credential
    has_one :vendor                             # See Vendor.all_credential
  end

  class DataStore
    identified_by :data_store_name
    has_one :client                             # See Client.all_data_store
    one_to_one :data_store_name, DataStore_Name  # See DataStore_Name.data_store
    one_to_one :friendly_name, Name             # See Name.data_store_as_friendly_name
    has_one :geocode_file                       # See GeocodeFile.all_data_store
    has_one :heart_beat_truck_pcid, TruckPCID   # See TruckPCID.all_data_store_as_heart_beat_truck_pcid
    one_to_one :internal_credential, Credential  # See Credential.data_store_as_internal_credential
    has_one :major_version, Version             # See Version.all_data_store_as_major_version
    has_one :minor_version, Version             # See Version.all_data_store_as_minor_version
    has_one :primary_host_system, "HostSystem"  # See HostSystem.all_data_store_as_primary_host_system
    has_one :revision_version, Version          # See Version.all_data_store_as_revision_version
    has_one :secondary_host_system, "HostSystem"  # See HostSystem.all_data_store_as_secondary_host_system
  end

  class Date
    identified_by :ddmmyyyy
    one_to_one :ddmmyyyy, DDMMYYYY              # See DDMMYYYY.date
  end

  class DateTime
    identified_by :mdyhms
    one_to_one :mdyhms, MDYHMS                  # See MDYHMS.date_time
  end

  class Duration
    identified_by :seconds
    one_to_one :seconds                         # See Seconds.duration
  end

  class GeocodeFile
    identified_by :path
    one_to_one :path                            # See Path.geocode_file
  end

  class HostSystem
    identified_by :host_system_name
    one_to_one :host_system_name, HostSystem_Name  # See HostSystem_Name.host_system
  end

  class Monitor
    identified_by :monitor_id
    has_one :data_store                         # See DataStore.all_monitor
    maybe :is_disabled
    one_to_one :monitor_id, Monitor_Id          # See Monitor_Id.monitor
    has_one :monitoring_application             # See MonitoringApplication.all_monitor
  end

  class MonitoringApplication
    identified_by :monitoring_application_name
    one_to_one :monitoring_application_name, MonitoringApplication_Name  # See MonitoringApplication_Name.monitoring_application
  end

  class Network
    identified_by :network_nr
    has_one :company, :origin_network           # See Company.all_origin_network
    has_one :data_store, :tcp_proxy_network     # See DataStore.all_tcp_proxy_network
    has_one :domain_name, Name                  # See Name.all_network_as_domain_name
    one_to_one :ending_ip, IP                   # See IP.network_as_ending_ip
    has_one :host_system                        # See HostSystem.all_network
    one_to_one :initial_ip, IP                  # See IP.network_as_initial_ip
    maybe :is_ip_range
    maybe :is_ip_single
    maybe :is_ip_subnet
    has_one :netmask                            # See Netmask.all_network
    one_to_one :network_nr, Network_Nr          # See Network_Nr.network
    has_one :private_interface_switch, "Switch", :private_network  # See Switch.all_private_network
    has_one :public_interface_switch, "Switch", :public_network  # See Switch.all_public_network
  end

  class NotificationLevel
    identified_by :notification_level_nr
    has_one :initial_delay_duration, Duration   # See Duration.all_notification_level_as_initial_delay_duration
    one_to_one :notification_level_nr, NotificationLevel_Nr  # See NotificationLevel_Nr.notification_level
    has_one :repeat_duration, Duration          # See Duration.all_notification_level_as_repeat_duration
  end

  class NotificationType
    identified_by :notification_type_name
    one_to_one :notification_type_name, NotificationType_Name  # See NotificationType_Name.notification_type
  end

  class MonitorNotificationType
    identified_by :monitor, :notification_type
    has_one :monitor                            # See Monitor.all_monitor_notification_type
    has_one :notification_type                  # See NotificationType.all_monitor_notification_type
    maybe :is_excluded
  end

  class ProviderType
    identified_by :provider_type_id
    one_to_one :provider_type_id, ProviderType_Id  # See ProviderType_Id.provider_type
  end

  class RecurringSchedule
    identified_by :recurring_schedule_id
    has_one :duration                           # See Duration.all_recurring_schedule
    maybe :friday
    maybe :monday
    has_one :monitor_all_exclusion, Monitor, :all_exclusion_recurring_schedule  # See Monitor.all_all_exclusion_recurring_schedule
    has_one :monitor_integration_exclusion, Monitor, :integration_exclusion_recurring_schedule  # See Monitor.all_integration_exclusion_recurring_schedule
    one_to_one :recurring_schedule_id, RecurringSchedule_Id  # See RecurringSchedule_Id.recurring_schedule
    maybe :saturday
    has_one :start_time, "Time"                 # See Time.all_recurring_schedule_as_start_time
    maybe :sunday
    maybe :thursday
    maybe :tuesday
    maybe :wednesday
  end

  class SatalliteMessage
    identified_by :satallite_message_id
    has_one :data_store                         # See DataStore.all_satallite_message
    has_one :group_transaction, "Transaction"   # See Transaction.all_satallite_message_as_group_transaction
    has_one :insertion_date_time, DateTime      # See DateTime.all_satallite_message_as_insertion_date_time
    has_one :message_data                       # See MessageData.all_satallite_message
    has_one :message_header                     # See MessageHeader.all_satallite_message
    has_one :provider_type                      # See ProviderType.all_satallite_message
    one_to_one :satallite_message_id, SatalliteMessage_Id  # See SatalliteMessage_Id.satallite_message
    has_one :serial_number                      # See SerialNumber.all_satallite_message
  end

  class Subscription
    identified_by :subscription_nr
    has_one :beginning_date, Date               # See Date.all_subscription_as_beginning_date
    one_to_one :driver_tech_subscription, Company, :driver_tech_subscription  # See Company.driver_tech_subscription
    has_one :ending_date, Date                  # See Date.all_subscription_as_ending_date
    maybe :is_enabled
    one_to_one :subscription_nr, Subscription_Nr  # See Subscription_Nr.subscription
  end

  class Switch
    identified_by :switch_id
    one_to_one :data_store, :legacy_switch      # See DataStore.legacy_switch
    maybe :is_backup_messages
    maybe :is_backup_updates
    maybe :is_send_disabled
    maybe :is_test_vectors_enabled
    has_one :major_version, Version             # See Version.all_switch_as_major_version
    has_one :minor_version, Version             # See Version.all_switch_as_minor_version
    one_to_one :monitoring_port, Port           # See Port.switch_as_monitoring_port
    has_one :operating_port, Port               # See Port.all_switch_as_operating_port
    has_one :revision_version, Version          # See Version.all_switch_as_revision_version
    one_to_one :switch_id, Switch_Id            # See Switch_Id.switch
  end

  class HostSystemRunsSwitch
    identified_by :host_system, :switch
    has_one :host_system                        # See HostSystem.all_host_system_runs_switch
    has_one :switch                             # See Switch.all_host_system_runs_switch
  end

  class Time
    identified_by :hhmmss
    one_to_one :hhmmss, HHMMSS                  # See HHMMSS.time
  end

  class Transaction
    identified_by :transaction_nr
    one_to_one :transaction_nr, Transaction_Nr  # See Transaction_Nr.transaction
  end

  class User
    identified_by :user_name
    maybe :is_monitor_notification_disabled
    has_one :primary_email_address, EmailAddress  # See EmailAddress.all_user_as_primary_email_address
    has_one :secondary_email_address, EmailAddress  # See EmailAddress.all_user_as_secondary_email_address
    one_to_one :user_name, User_Name            # See User_Name.user
  end

  class MonitorNotificationUser
    identified_by :monitor_notification_type, :notification_user
    has_one :monitor_notification_type          # See MonitorNotificationType.all_monitor_notification_user
    has_one :notification_user, User            # See User.all_monitor_notification_user_as_notification_user
    has_one :notification_level                 # See NotificationLevel.all_monitor_notification_user
  end

  class Vendor < Company
  end

  class Client < Company
    has_one :default_data_store, DataStore      # See DataStore.all_client_as_default_data_store
  end

  class FileHostSystem < HostSystem
    has_one :port                               # See Port.all_file_host_system
  end

  class DataStoreFileHostSystem
    identified_by :data_store
    one_to_one :data_store                      # See DataStore.data_store_file_host_system
    has_one :file_host_system                   # See FileHostSystem.all_data_store_file_host_system
    one_to_one :internal_credential, Credential  # See Credential.data_store_file_host_system_as_internal_credential
  end

  class Service
    identified_by :vendor, :service_type
    has_one :service_type                       # See ServiceType.all_service
    has_one :vendor                             # See Vendor.all_service
  end

  class DataStoreService
    identified_by :service, :data_store
    has_one :data_store                         # See DataStore.all_data_store_service
    has_one :service                            # See Service.all_data_store_service
    has_one :client                             # See Client.all_data_store_service
    one_to_one :subscription, :data_store_service_subscription  # See Subscription.data_store_service_subscription
  end

end
