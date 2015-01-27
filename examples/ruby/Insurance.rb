require 'activefacts/api'

module ::Insurance

  class Alias < Char
    value_type :length => 3
    one_to_one :product                         # See Product.alias
  end

  class ApplicationNr < SignedInteger
    value_type :length => 32
    one_to_one :application                     # See Application.application_nr
  end

  class AssetID < AutoCounter
    value_type 
    one_to_one :asset                           # See Asset.asset_id
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
    one_to_one :claim                           # See Claim.claim_id
  end

  class ClaimSequence < UnsignedInteger
    value_type :length => 32
    restrict 1..999
  end

  class Colour < String
    value_type 
  end

  class ContactMethod < Char
    value_type :length => 1
    restrict 'B', 'H', 'M'
  end

  class Count < UnsignedInteger
    value_type :length => 32
  end

  class CoverTypeCode < Char
    value_type 
    one_to_one :cover_type                      # See CoverType.cover_type_code
  end

  class CoverTypeName < String
    value_type 
    one_to_one :cover_type                      # See CoverType.cover_type_name
  end

  class Date < ::Date
    value_type 
  end

  class DateTime < ::DateTime
    value_type 
  end

  class Description < String
    value_type :length => 1024
    one_to_one :product                         # See Product.description
  end

  class Email < String
    value_type 
  end

  class EngineNumber < String
    value_type 
  end

  class HospitalName < String
    value_type 
    one_to_one :hospital                        # See Hospital.hospital_name
  end

  class ITCClaimed < Decimal
    value_type :length => 18, :scale => 2
    restrict 0.0..100.0
  end

  class Intoxication < String
    value_type 
  end

  class LiabilityCode < Char
    value_type :length => 1
    restrict 'D', 'L', 'R', 'U'
    one_to_one :liability, :restrict => ['D', 'L', 'R', 'U']  # See Liability.liability_code
  end

  class LicenseNumber < String
    value_type 
    one_to_one :license                         # See License.license_number
  end

  class LicenseType < String
    value_type 
  end

  class Location < String
    value_type 
  end

  class LossTypeCode < Char
    value_type 
    one_to_one :loss_type                       # See LossType.loss_type_code
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
    one_to_one :party                           # See Party.party_id
  end

  class PhoneNr < String
    value_type 
    one_to_one :phone                           # See Phone.phone_nr
  end

  class Place < String
    value_type 
  end

  class PolicySerial < UnsignedInteger
    value_type :length => 32
    restrict 1..99999
  end

  class PolicyWordingText < String
    value_type 
    one_to_one :policy_wording                  # See PolicyWording.policy_wording_text
  end

  class Postcode < String
    value_type 
  end

  class Price < Decimal
    value_type :length => 18, :scale => 2
  end

  class ProductCode < UnsignedInteger
    value_type :length => 8
    restrict 1..99
    one_to_one :product                         # See Product.product_code
  end

  class Reason < String
    value_type 
  end

  class RegistrationNr < Char
    value_type :length => 8
    one_to_one :registration                    # See Registration.registration_nr
  end

  class ReportNr < SignedInteger
    value_type :length => 32
  end

  class StateCode < UnsignedInteger
    value_type :length => 8
    restrict 0..9
    one_to_one :state                           # See State.state_code
  end

  class StateName < String
    value_type :length => 256
    one_to_one :state                           # See State.state_name
  end

  class Street < String
    value_type :length => 256
  end

  class TestResult < String
    value_type 
  end

  class Text < String
    value_type 
    one_to_one :underwriting_question           # See UnderwritingQuestion.text
  end

  class Time < ::Time
    value_type 
  end

  class Title < String
    value_type 
  end

  class UnderwritingQuestionID < AutoCounter
    value_type 
    one_to_one :underwriting_question           # See UnderwritingQuestion.underwriting_question_id
  end

  class VIN < UnsignedInteger
    value_type :length => 32
    one_to_one :vehicle                         # See Vehicle.vin
  end

  class YearNr < SignedInteger
    value_type :length => 32
    one_to_one :year                            # See Year.year_nr
  end

  class Application
    identified_by :application_nr
    one_to_one :application_nr, :mandatory => true  # See ApplicationNr.application
  end

  class Asset
    identified_by :asset_id
    one_to_one :asset_id, :class => AssetID, :mandatory => true  # See AssetID.asset
  end

  class Claim
    identified_by :claim_id
    one_to_one :claim_id, :class => ClaimID, :mandatory => true  # See ClaimID.claim
    has_one :p_sequence, :class => ClaimSequence, :mandatory => true  # See ClaimSequence.all_claim_as_p_sequence
    has_one :policy, :mandatory => true         # See Policy.all_claim
  end

  class CoverType
    identified_by :cover_type_code
    one_to_one :cover_type_code, :mandatory => true  # See CoverTypeCode.cover_type
    one_to_one :cover_type_name, :mandatory => true  # See CoverTypeName.cover_type
  end

  class Hospital
    identified_by :hospital_name
    one_to_one :hospital_name, :mandatory => true  # See HospitalName.hospital
  end

  class Incident
    identified_by :claim
    has_one :address, :mandatory => true        # See Address.all_incident
    one_to_one :claim, :mandatory => true       # See Claim.incident
    has_one :date_time, :mandatory => true      # See DateTime.all_incident
  end

  class Liability
    identified_by :liability_code
    one_to_one :liability_code, :mandatory => true  # See LiabilityCode.liability
  end

  class LossType
    identified_by :loss_type_code
    maybe :involves_driving
    maybe :is_single_vehicle_incident
    has_one :liability                          # See Liability.all_loss_type
    one_to_one :loss_type_code, :mandatory => true  # See LossTypeCode.loss_type
  end

  class LostItem
    identified_by :incident, :lost_item_nr
    has_one :description, :mandatory => true    # See Description.all_lost_item
    has_one :incident, :mandatory => true       # See Incident.all_lost_item
    has_one :lost_item_nr, :mandatory => true   # See LostItemNr.all_lost_item
    has_one :purchase_date, :class => Date      # See Date.all_lost_item_as_purchase_date
    has_one :purchase_place, :class => Place    # See Place.all_lost_item_as_purchase_place
    has_one :purchase_price, :class => Price    # See Price.all_lost_item_as_purchase_price
  end

  class Party
    identified_by :party_id
    maybe :is_a_company
    one_to_one :party_id, :class => PartyID, :mandatory => true  # See PartyID.party
    has_one :postal_address, :class => "Address"  # See Address.all_party_as_postal_address
  end

  class Person < Party
    has_one :address                            # See Address.all_person
    has_one :birth_date, :class => Date         # See Date.all_person_as_birth_date
    has_one :family_name, :class => Name, :mandatory => true  # See Name.all_person_as_family_name
    has_one :given_name, :class => Name, :mandatory => true  # See Name.all_person_as_given_name
    has_one :occupation                         # See Occupation.all_person
    has_one :title, :mandatory => true          # See Title.all_person
  end

  class Phone
    identified_by :phone_nr
    one_to_one :phone_nr, :mandatory => true    # See PhoneNr.phone
  end

  class PoliceReport
    identified_by :incident
    one_to_one :incident, :mandatory => true    # See Incident.police_report
    has_one :officer_name, :class => Name       # See Name.all_police_report_as_officer_name
    has_one :police_report_nr, :class => ReportNr  # See ReportNr.all_police_report_as_police_report_nr
    has_one :report_date_time, :class => DateTime  # See DateTime.all_police_report_as_report_date_time
    has_one :reporter_name, :class => Name      # See Name.all_police_report_as_reporter_name
    has_one :station_name, :class => Name       # See Name.all_police_report_as_station_name
  end

  class PolicyWording
    identified_by :policy_wording_text
    one_to_one :policy_wording_text, :mandatory => true  # See PolicyWordingText.policy_wording
  end

  class Product
    identified_by :product_code
    one_to_one :alias                           # See Alias.product
    one_to_one :description                     # See Description.product
    one_to_one :product_code, :mandatory => true  # See ProductCode.product
  end

  class Registration
    identified_by :registration_nr
    one_to_one :registration_nr, :mandatory => true  # See RegistrationNr.registration
  end

  class State
    identified_by :state_code
    one_to_one :state_code, :mandatory => true  # See StateCode.state
    one_to_one :state_name                      # See StateName.state
  end

  class UnderwritingQuestion
    identified_by :underwriting_question_id
    one_to_one :text, :mandatory => true        # See Text.underwriting_question
    one_to_one :underwriting_question_id, :class => UnderwritingQuestionID, :mandatory => true  # See UnderwritingQuestionID.underwriting_question
  end

  class Vehicle < Asset
    identified_by :vin
    has_one :colour                             # See Colour.all_vehicle
    has_one :dealer                             # See Dealer.all_vehicle
    has_one :engine_number                      # See EngineNumber.all_vehicle
    has_one :finance_institution                # See FinanceInstitution.all_vehicle
    maybe :has_commercial_registration
    has_one :model_year, :class => "Year", :mandatory => true  # See Year.all_vehicle_as_model_year
    has_one :registration, :mandatory => true   # See Registration.all_vehicle
    has_one :vehicle_type, :mandatory => true   # See VehicleType.all_vehicle
    one_to_one :vin, :class => VIN, :mandatory => true  # See VIN.vehicle
  end

  class VehicleIncident < Incident
    has_one :description                        # See Description.all_vehicle_incident
    has_one :loss_type                          # See LossType.all_vehicle_incident
    has_one :previous_damage_description, :class => Description  # See Description.all_vehicle_incident_as_previous_damage_description
    has_one :reason                             # See Reason.all_vehicle_incident
    has_one :towed_location, :class => Location  # See Location.all_vehicle_incident_as_towed_location
    has_one :weather_description, :class => Description  # See Description.all_vehicle_incident_as_weather_description
  end

  class VehicleType
    identified_by :make, :model, :badge
    has_one :badge                              # See Badge.all_vehicle_type
    has_one :make, :mandatory => true           # See Make.all_vehicle_type
    has_one :model, :mandatory => true          # See Model.all_vehicle_type
  end

  class Witness
    identified_by :incident, :name
    has_one :address                            # See Address.all_witness
    has_one :contact_phone, :class => Phone     # See Phone.all_witness_as_contact_phone
    has_one :incident, :mandatory => true       # See Incident.all_witness
    has_one :name, :mandatory => true           # See Name.all_witness
  end

  class Year
    identified_by :year_nr
    one_to_one :year_nr, :mandatory => true     # See YearNr.year
  end

  class Address
    identified_by :street, :city, :postcode, :state
    has_one :city, :mandatory => true           # See City.all_address
    has_one :postcode                           # See Postcode.all_address
    has_one :state                              # See State.all_address
    has_one :street, :mandatory => true         # See Street.all_address
  end

  class AuthorisedRep < Party
  end

  class Company < Party
    has_one :contact_person, :class => Person, :mandatory => true  # See Person.all_company_as_contact_person
  end

  class ContactMethods
    identified_by :person
    has_one :business_phone, :class => Phone    # See Phone.all_contact_methods_as_business_phone
    has_one :contact_time, :class => Time       # See Time.all_contact_methods_as_contact_time
    has_one :email                              # See Email.all_contact_methods
    has_one :home_phone, :class => Phone        # See Phone.all_contact_methods_as_home_phone
    has_one :mobile_phone, :class => Phone      # See Phone.all_contact_methods_as_mobile_phone
    one_to_one :person, :mandatory => true      # See Person.contact_methods
    has_one :preferred_contact_method, :class => ContactMethod  # See ContactMethod.all_contact_methods_as_preferred_contact_method
  end

  class Contractor < Company
  end

  class ContractorAppointment
    identified_by :claim, :contractor
    has_one :claim, :mandatory => true          # See Claim.all_contractor_appointment
    has_one :contractor, :mandatory => true     # See Contractor.all_contractor_appointment
  end

  class CoverWording
    identified_by :cover_type, :policy_wording, :start_date
    has_one :cover_type, :mandatory => true     # See CoverType.all_cover_wording
    has_one :policy_wording, :mandatory => true  # See PolicyWording.all_cover_wording
    has_one :start_date, :class => Date, :mandatory => true  # See Date.all_cover_wording_as_start_date
  end

  class Dealer < Party
  end

  class Driving
    identified_by :vehicle_incident
    one_to_one :vehicle_incident, :mandatory => true  # See VehicleIncident.driving
    has_one :breath_test_result, :class => TestResult  # See TestResult.all_driving_as_breath_test_result
    has_one :intoxication                       # See Intoxication.all_driving
    has_one :nonconsent_reason, :class => Reason  # See Reason.all_driving_as_nonconsent_reason
    has_one :person                             # See Person.all_driving
    has_one :unlicensed_reason, :class => Reason  # See Reason.all_driving_as_unlicensed_reason
  end

  class DrivingCharge
    identified_by :driving
    has_one :charge, :mandatory => true         # See Charge.all_driving_charge
    one_to_one :driving, :mandatory => true     # See Driving.driving_charge
    maybe :is_a_warning
  end

  class FinanceInstitution < Company
  end

  class Hospitalization
    identified_by :driving
    one_to_one :driving, :mandatory => true     # See Driving.hospitalization
    has_one :hospital, :mandatory => true       # See Hospital.all_hospitalization
    has_one :blood_test_result, :class => TestResult  # See TestResult.all_hospitalization_as_blood_test_result
  end

  class Insured < Party
  end

  class Insurer < Company
  end

  class Investigator < Contractor
  end

  class License
    identified_by :person
    maybe :is_international
    one_to_one :license_number, :mandatory => true  # See LicenseNumber.license
    has_one :license_type, :mandatory => true   # See LicenseType.all_license
    one_to_one :person, :mandatory => true      # See Person.license
    has_one :year                               # See Year.all_license
  end

  class Lodgement
    identified_by :claim
    one_to_one :claim, :mandatory => true       # See Claim.lodgement
    has_one :person, :mandatory => true         # See Person.all_lodgement
    has_one :date_time                          # See DateTime.all_lodgement
  end

  class Policy
    identified_by :p_year, :p_product, :p_state, :p_serial
    has_one :application, :mandatory => true    # See Application.all_policy
    has_one :authorised_rep                     # See AuthorisedRep.all_policy
    has_one :insured, :mandatory => true        # See Insured.all_policy
    has_one :itc_claimed, :class => ITCClaimed  # See ITCClaimed.all_policy
    has_one :p_product, :class => Product, :mandatory => true  # See Product.all_policy_as_p_product
    has_one :p_serial, :class => PolicySerial, :mandatory => true  # See PolicySerial.all_policy_as_p_serial
    has_one :p_state, :class => State, :mandatory => true  # See State.all_policy_as_p_state
    has_one :p_year, :class => Year, :mandatory => true  # See Year.all_policy_as_p_year
  end

  class PropertyDamage
    identified_by :incident, :address
    has_one :address, :mandatory => true        # See Address.all_property_damage
    has_one :incident                           # See Incident.all_property_damage
    has_one :owner_name, :class => Name         # See Name.all_property_damage_as_owner_name
    has_one :phone                              # See Phone.all_property_damage
  end

  class Repairer < Contractor
  end

  class Solicitor < Contractor
  end

  class ThirdParty
    identified_by :person, :vehicle_incident
    has_one :person, :mandatory => true         # See Person.all_third_party
    has_one :vehicle_incident, :mandatory => true  # See VehicleIncident.all_third_party
    has_one :insurer                            # See Insurer.all_third_party
    has_one :model_year, :class => Year         # See Year.all_third_party_as_model_year
    has_one :vehicle_registration, :class => Registration  # See Registration.all_third_party_as_vehicle_registration
    has_one :vehicle_type                       # See VehicleType.all_third_party
  end

  class UnderwritingDemerit
    identified_by :vehicle_incident, :underwriting_question
    has_one :occurrence_count, :class => Count  # See Count.all_underwriting_demerit_as_occurrence_count
    has_one :underwriting_question, :mandatory => true  # See UnderwritingQuestion.all_underwriting_demerit
    has_one :vehicle_incident, :mandatory => true  # See VehicleIncident.all_underwriting_demerit
  end

  class Assessor < Contractor
  end

  class Cover
    identified_by :policy, :cover_type, :asset
    has_one :asset, :mandatory => true          # See Asset.all_cover
    has_one :cover_type, :mandatory => true     # See CoverType.all_cover
    has_one :policy, :mandatory => true         # See Policy.all_cover
  end

  class MotorPolicy < Policy
  end

  class SingleMotorPolicy < MotorPolicy
  end

  class MotorFleetPolicy < MotorPolicy
  end

end
