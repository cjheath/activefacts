require 'activefacts/api'

module ::Insurance

  class Alias < FixedLengthText
    value_type :length => 3
  end

  class ApplicationNr < SignedInteger
    value_type :length => 32
  end

  class AssetID < AutoCounter
    value_type 
  end

  class Badge < String
    value_type 
  end

  class Charge < String
    value_type 
  end

  class City < String
    value_type 
  end

  class ClaimID < AutoCounter
    value_type 
  end

  class ClaimSequence < UnsignedInteger
    value_type :length => 32
    # REVISIT: ClaimSequence has restricted values
  end

  class Colour < String
    value_type 
  end

  class ContactMethod < FixedLengthText
    value_type :length => 1
    # REVISIT: ContactMethod has restricted values
  end

  class Count < UnsignedInteger
    value_type :length => 32
  end

  class CoverTypeCode < FixedLengthText
    value_type 
  end

  class CoverTypeName < String
    value_type 
  end

  class Date < ::Date
    value_type 
  end

  class DateTime < ::DateTime
    value_type 
  end

  class DemeritKindName < String
    value_type 
  end

  class Description < String
    value_type :length => 1024
  end

  class Email < String
    value_type 
  end

  class EngineNumber < String
    value_type 
  end

  class ITCClaimed < Decimal
    value_type :length => 18, :scale => 2
    # REVISIT: ITCClaimed has restricted values
  end

  class Intoxication < String
    value_type 
  end

  class LiabilityCode < FixedLengthText
    value_type :length => 1
    # REVISIT: LiabilityCode has restricted values
  end

  class LicenseNumber < String
    value_type 
  end

  class LicenseType < String
    value_type 
  end

  class Location < String
    value_type 
  end

  class LossTypeCode < FixedLengthText
    value_type 
  end

  class LostItemNr < SignedInteger
    value_type :length => 32
  end

  class Make < String
    value_type 
  end

  class Model < String
    value_type 
  end

  class Name < String
    value_type :length => 256
  end

  class Occupation < String
    value_type 
  end

  class PartyID < AutoCounter
    value_type 
  end

  class PhoneNr < String
    value_type 
  end

  class Place < String
    value_type 
  end

  class PolicySerial < UnsignedInteger
    value_type :length => 32
    # REVISIT: PolicySerial has restricted values
  end

  class PolicyWordingText < String
    value_type 
  end

  class Postcode < String
    value_type 
  end

  class Price < Decimal
    value_type :length => 18, :scale => 2
  end

  class ProdDescription < String
    value_type :length => 80
  end

  class ProductCode < UnsignedTinyInteger
    value_type :length => 32
    # REVISIT: ProductCode has restricted values
  end

  class Reason < String
    value_type 
  end

  class RegistrationNr < FixedLengthText
    value_type :length => 8
  end

  class ReportNr < SignedInteger
    value_type :length => 32
  end

  class StateCode < UnsignedTinyInteger
    value_type :length => 32
    # REVISIT: StateCode has restricted values
  end

  class StateName < String
    value_type :length => 256
  end

  class Street < String
    value_type :length => 256
  end

  class TestResult < String
    value_type 
  end

  class Time < ::Time
    value_type 
  end

  class Title < String
    value_type 
  end

  class VIN < UnsignedInteger
    value_type :length => 32
  end

  class YearNr < SignedInteger
    value_type :length => 32
  end

  class Application
    identified_by :application_nr
    one_to_one :application_nr                  # See ApplicationNr.application
  end

  class Asset
    identified_by :asset_id
    one_to_one :asset_id, AssetID               # See AssetID.asset
  end

  class Claim
    identified_by :claim_id
    one_to_one :claim_id, ClaimID               # See ClaimID.claim
    has_one :p_sequence, ClaimSequence          # See ClaimSequence.all_claim_as_p_sequence
    has_one :policy                             # See Policy.all_claim
  end

  class CoverType
    identified_by :cover_type_code
    one_to_one :cover_type_code                 # See CoverTypeCode.cover_type
    one_to_one :cover_type_name                 # See CoverTypeName.cover_type
  end

  class DemeritKind
    identified_by :demerit_kind_name
    one_to_one :demerit_kind_name               # See DemeritKindName.demerit_kind
  end

  class Incident
    identified_by :claim
    has_one :address                            # See Address.all_incident
    one_to_one :claim                           # See Claim.incident
    has_one :date_time                          # See DateTime.all_incident
  end

  class Liability
    identified_by :liability_code
    one_to_one :liability_code                  # See LiabilityCode.liability
  end

  class LossType
    identified_by :loss_type_code
    maybe :involves_driving
    maybe :is_single_vehicle_incident
    has_one :liability                          # See Liability.all_loss_type
    one_to_one :loss_type_code                  # See LossTypeCode.loss_type
  end

  class LostItem
    identified_by :incident, :lost_item_nr
    has_one :description                        # See Description.all_lost_item
    has_one :incident                           # See Incident.all_lost_item
    has_one :lost_item_nr                       # See LostItemNr.all_lost_item
    has_one :purchase_date, Date                # See Date.all_lost_item_as_purchase_date
    has_one :purchase_place, Place              # See Place.all_lost_item_as_purchase_place
    has_one :purchase_price, Price              # See Price.all_lost_item_as_purchase_price
  end

  class Party
    identified_by :party_id
    maybe :is_a_company
    one_to_one :party_id, PartyID               # See PartyID.party
    has_one :postal_address, "Address"          # See Address.all_party_as_postal_address
  end

  class Person < Party
    has_one :address                            # See Address.all_person
    has_one :birth_date, Date                   # See Date.all_person_as_birth_date
    has_one :family_name, Name                  # See Name.all_person_as_family_name
    has_one :given_name, Name                   # See Name.all_person_as_given_name
    has_one :occupation                         # See Occupation.all_person
    has_one :title                              # See Title.all_person
  end

  class Lodgement
    identified_by :claim
    one_to_one :claim                           # See Claim.lodgement
    has_one :person                             # See Person.all_lodgement
    has_one :date_time                          # See DateTime.all_lodgement
  end

  class Phone
    identified_by :phone_nr
    one_to_one :phone_nr                        # See PhoneNr.phone
  end

  class PoliceReport
    identified_by :incident
    one_to_one :incident                        # See Incident.police_report
    has_one :officer_name, Name                 # See Name.all_police_report_as_officer_name
    has_one :police_report_nr, ReportNr         # See ReportNr.all_police_report_as_police_report_nr
    has_one :report_date_time, DateTime         # See DateTime.all_police_report_as_report_date_time
    has_one :reporter_name, Name                # See Name.all_police_report_as_reporter_name
    has_one :station_name, Name                 # See Name.all_police_report_as_station_name
  end

  class PolicyWording
    identified_by :policy_wording_text
    one_to_one :policy_wording_text             # See PolicyWordingText.policy_wording
  end

  class CoverWording
    identified_by :cover_type, :policy_wording, :start_date
    has_one :cover_type                         # See CoverType.all_cover_wording
    has_one :policy_wording                     # See PolicyWording.all_cover_wording
    has_one :start_date, Date                   # See Date.all_cover_wording_as_start_date
  end

  class Product
    identified_by :product_code
    one_to_one :alias                           # See Alias.product
    one_to_one :prod_description                # See ProdDescription.product
    one_to_one :product_code                    # See ProductCode.product
  end

  class Registration
    identified_by :registration_nr
    one_to_one :registration_nr                 # See RegistrationNr.registration
  end

  class State
    identified_by :state_code
    one_to_one :state_code                      # See StateCode.state
    one_to_one :state_name                      # See StateName.state
  end

  class Vehicle < Asset
    identified_by :vin
    has_one :colour                             # See Colour.all_vehicle
    has_one :dealer                             # See Dealer.all_vehicle
    has_one :engine_number                      # See EngineNumber.all_vehicle
    has_one :finance_institution                # See FinanceInstitution.all_vehicle
    maybe :has_commercial_registration
    has_one :model_year, "Year"                 # See Year.all_vehicle_as_model_year
    has_one :registration                       # See Registration.all_vehicle
    has_one :vehicle_type                       # See VehicleType.all_vehicle
    one_to_one :vin, VIN                        # See VIN.vehicle
  end

  class VehicleIncident < Incident
    has_one :description                        # See Description.all_vehicle_incident
    has_one :loss_type                          # See LossType.all_vehicle_incident
    has_one :previous_damage_description, Description  # See Description.all_vehicle_incident_as_previous_damage_description
    has_one :reason                             # See Reason.all_vehicle_incident
    has_one :towed_location, Location           # See Location.all_vehicle_incident_as_towed_location
    has_one :weather_description, Description   # See Description.all_vehicle_incident_as_weather_description
  end

  class ThirdParty
    identified_by :person, :vehicle_incident
    has_one :person                             # See Person.all_third_party
    has_one :vehicle_incident                   # See VehicleIncident.all_third_party
    has_one :insurer                            # See Insurer.all_third_party
    has_one :model_year, "Year"                 # See Year.all_third_party_as_model_year
    has_one :vehicle_registration, Registration  # See Registration.all_third_party_as_vehicle_registration
    has_one :vehicle_type                       # See VehicleType.all_third_party
  end

  class VehicleType
    identified_by :make, :model, :badge
    has_one :badge                              # See Badge.all_vehicle_type
    has_one :make                               # See Make.all_vehicle_type
    has_one :model                              # See Model.all_vehicle_type
  end

  class Witness
    identified_by :incident, :name
    has_one :address                            # See Address.all_witness
    has_one :contact_phone, Phone               # See Phone.all_witness_as_contact_phone
    has_one :incident                           # See Incident.all_witness
    has_one :name                               # See Name.all_witness
  end

  class Year
    identified_by :year_nr
    one_to_one :year_nr                         # See YearNr.year
  end

  class Address
    identified_by :street, :city, :postcode, :state
    has_one :city                               # See City.all_address
    has_one :postcode                           # See Postcode.all_address
    has_one :state                              # See State.all_address
    has_one :street                             # See Street.all_address
  end

  class AuthorisedRep < Party
  end

  class Client < Party
  end

  class Company < Party
    has_one :contact_person, Person             # See Person.all_company_as_contact_person
  end

  class ContactMethods
    identified_by :person
    has_one :business_phone, Phone              # See Phone.all_contact_methods_as_business_phone
    has_one :contact_time, Time                 # See Time.all_contact_methods_as_contact_time
    has_one :email                              # See Email.all_contact_methods
    has_one :home_phone, Phone                  # See Phone.all_contact_methods_as_home_phone
    has_one :mobile_phone, Phone                # See Phone.all_contact_methods_as_mobile_phone
    one_to_one :person                          # See Person.contact_methods
    has_one :preferred_contact_method, ContactMethod  # See ContactMethod.all_contact_methods_as_preferred_contact_method
  end

  class Contractor < Company
  end

  class ContractorAppointment
    identified_by :claim, :contractor
    has_one :claim                              # See Claim.all_contractor_appointment
    has_one :contractor                         # See Contractor.all_contractor_appointment
  end

  class DamagedProperty
    identified_by :incident, :address
    has_one :address                            # See Address.all_damaged_property
    has_one :incident                           # See Incident.all_damaged_property
    has_one :owner_name, Name                   # See Name.all_damaged_property_as_owner_name
    has_one :phone                              # See Phone.all_damaged_property
  end

  class Dealer < Party
  end

  class Driver < Person
  end

  class Driving
    identified_by :vehicle_incident
    has_one :driver                             # See Driver.all_driving
    one_to_one :vehicle_incident                # See VehicleIncident.driving
    has_one :blood_test_result, TestResult      # See TestResult.all_driving_as_blood_test_result
    has_one :breath_test_result, TestResult     # See TestResult.all_driving_as_breath_test_result
    has_one :hospital_name, Name, :driver_hospitalised  # See Name.all_driver_hospitalised
    has_one :intoxication                       # See Intoxication.all_driving
    has_one :nonconsent_reason, Reason          # See Reason.all_driving_as_nonconsent_reason
    has_one :unlicensed_reason, Reason          # See Reason.all_driving_as_unlicensed_reason
  end

  class DrivingCharge
    identified_by :driving
    has_one :charge                             # See Charge.all_driving_charge
    one_to_one :driving                         # See Driving.driving_charge
    maybe :is_warning
  end

  class FinanceInstitution < Company
  end

  class Insurer < Company
  end

  class Investigator < Contractor
  end

  class License
    identified_by :driver
    one_to_one :driver                          # See Driver.license
    maybe :is_international
    one_to_one :license_number                  # See LicenseNumber.license
    has_one :license_type                       # See LicenseType.all_license
    has_one :year                               # See Year.all_license
  end

  class Policy
    identified_by :p_year, :p_product, :p_state, :p_serial
    has_one :application                        # See Application.all_policy
    has_one :authorised_rep                     # See AuthorisedRep.all_policy
    has_one :client                             # See Client.all_policy
    has_one :itcclaimed, ITCClaimed             # See ITCClaimed.all_policy
    has_one :p_product, Product                 # See Product.all_policy_as_p_product
    has_one :p_serial, PolicySerial             # See PolicySerial.all_policy_as_p_serial
    has_one :p_state, State                     # See State.all_policy_as_p_state
    has_one :p_year, Year                       # See Year.all_policy_as_p_year
  end

  class Cover
    identified_by :policy, :cover_type, :asset
    has_one :asset                              # See Asset.all_cover
    has_one :cover_type                         # See CoverType.all_cover
    has_one :policy                             # See Policy.all_cover
  end

  class Repairer < Contractor
  end

  class Solicitor < Contractor
  end

  class UnderwritingDemerit
    identified_by :vehicle_incident, :demerit_kind
    has_one :demerit_kind                       # See DemeritKind.all_underwriting_demerit
    has_one :occurrence_count, Count            # See Count.all_underwriting_demerit_as_occurrence_count
    has_one :vehicle_incident                   # See VehicleIncident.all_underwriting_demerit
  end

  class Assessor < Contractor
  end

  class MotorPolicy < Policy
  end

  class SingleMotorPolicy < MotorPolicy
  end

  class MotorFleetPolicy < MotorPolicy
  end

end
