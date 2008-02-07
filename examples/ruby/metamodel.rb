String.length Integer
Class.single Symbol, Symbol/Class, String
Class.multi Symbol, Symbol/Class, String

module ActiveFacts

  # Adjective = VariableLengthText(64);
  # Denominator = UnsignedInteger(32);
  # Enforcement = VariableLengthText(16);
  # Exponent = SignedSmallInteger(32);
  # Frequency = UnsignedInteger(32);
  # Length = UnsignedInteger(32);
  # Name = VariableLengthText(64);
  # Numerator = Decimal();
  # Ordinal = UnsignedSmallInteger(32);
  # ReadingText = VariableLengthText(256);
  # RingType = VariableLengthText();
  # Scale = UnsignedInteger(32);
  # Value = VariableLengthText(256);

  class Name < String
    length 64
  end

  # Feature = entity known by Name and Vocabulary:
  # 	Feature is called exactly one Name,
  # 	Feature belongs to at most one Vocabulary,
  # 	Vocabulary contains Feature;
  class Feature
    single :name, "is called"
    single :vocabulary, "belongs to"
  end

  # Vocabulary = subtype of Feature;
  # parent-Vocabulary contains Vocabulary [acyclic, intransitive],
  # 	Vocabulary extends at most one parent-Vocabulary;
  # Vocabulary contains Constraint,
  # 	Constraint belongs to at most one Vocabulary;
  class Vocabulary < Feature
    single :parent, Vocabulary
    multi :import, :Import, "imports"
    multi :population
  end

  class FactType
    # single :vocabulary
    single :fact_type_id
    single :nested_as, :Entity
    multi :reading
    multi :role
    multi :supertype, FactType
    multi :subtype, FactType
  end

  class Concept < Feature
  end

  class ValueType < Concept
    single :length
    single :scale
    single :unit
    multi :allowed_values, :ValueRange
  end

  class EntityType < Concept
    single :independent, Boolean
    single :personal, Boolean
    single :nests, :FactType, "nests/is nested as"
  end

  class Import
    single :vocabulary
    single :imported, Vocabulary
    multi :correspondence
  end

  class Alias < Feature
  end

  class Correspondence
    single :import
    single :imported, Feature
    single :local, Feature
  end

  # Bound = entity known by Value and InclusiveBound:
  # 	Bound has exactly one Value,
  # 	Value is of at least one Bound,
  # 	each Value is of some Bound,
  # 	Bound (as InclusiveBound) is inclusive;

  # Coefficient = entity known by Numerator and Denominator:
  # 	Coefficient has exactly one Numerator,
  # 	Coefficient has exactly one Denominator;
  # Coefficient is precise;

  # Constraint = entity known by Constraint_Id:
  # 	Constraint has exactly one Constraint_Id,
  # 	Constraint_Id is of at most one Constraint;
  # Name is of Constraint,
  # 	Constraint is called at most one Name;
  # Constraint requires at most one Enforcement;

  # Fact = entity known by Fact_Id:
  # 	Fact has exactly one Fact_Id,
  # 	Fact_Id is of at most one Fact;

  # FactType = entity known by FactType_Id:
  # 	FactType has exactly one FactType_Id,
  # 	FactType_Id is of at most one FactType;
  # Fact is of exactly one FactType;

  # Instance = entity known by Instance_Id:
  # 	Instance has exactly one Instance_Id,
  # 	Instance_Id is of at most one Instance;
  # Instance has at most one Value;

  # PresenceConstraint = subtype of Constraint;
  # PresenceConstraint has at most one max-Frequency;
  # PresenceConstraint has at most one min-Frequency;
  # PresenceConstraint is preferred identifier;
  # PresenceConstraint is mandatory;

  # Reading = entity known by Ordinal and FactType:
  # 	Reading is in at most one Ordinal position,
  # 	Ordinal reading for fact type is Reading,
  # 	FactType has at least one Reading,
  # 	each FactType has some Reading,
  # 	Reading is for exactly one FactType;
  # Reading has exactly one ReadingText;

  # RingConstraint = subtype of Constraint;
  # RingConstraint is of exactly one RingType;

  # Role = entity known by Role_Id:
  # 	Role has exactly one Role_Id,
  # 	Role_Id is of at most one Role;
  # Role is of RingConstraint,
  # 	RingConstraint has at most one Role;
  # other-Role is of RingConstraint,
  # 	RingConstraint has at most one other-Role;

  # RoleSequence = entity known by RoleSequence_Id:
  # 	RoleSequence has exactly one RoleSequence_Id,
  # 	RoleSequence_Id is of at most one RoleSequence;
  # Reading is in exactly one RoleSequence,
  # 	RoleSequence is for Reading;
  # PresenceConstraint covers exactly one RoleSequence;

  # RoleValue = entity known by Instance and Fact:
  # 	Instance plays RoleValue,
  # 	RoleValue is of exactly one Instance,
  # 	RoleValue fulfils exactly one Fact,
  # 	some RoleValue fulfils each Fact;
  # RoleValue is of exactly one Role;

  # SetConstraint = subtype of Constraint;

  # SubsetConstraint = subtype of SetConstraint;
  # SubsetConstraint covers exactly one superset-RoleSequence;
  # SubsetConstraint covers exactly one subset-RoleSequence;

  # UniquenessConstraint = subtype of PresenceConstraint;

  # Unit = entity known by Unit_Id:
  # 	Unit has exactly one Unit_Id,
  # 	Unit_Id is of at most one Unit;
  # Unit has at most one Coefficient;
  # Name is of Unit,
  # 	Unit is called exactly one Name;
  # Unit is fundamental;

  # ValueRange = entity known by minimum-Bound and maximum-Bound:
  # 	ValueRange has at most one minimum-Bound,
  # 	ValueRange has at most one maximum-Bound;

  # ValueRestriction = entity known by ValueRestriction_Id:
  # 	ValueRestriction has exactly one ValueRestriction_Id,
  # 	ValueRestriction_Id is of at most one ValueRestriction;
  # ValueRestrictionAllowsValueRange = ValueRestriction allows at least one ValueRange,
  # 	each ValueRestriction allows some ValueRange;
  # Role has at most one ValueRestriction,
  # 	ValueRestriction applies to Role;

  # BaseUnit = entity known by base-Unit and Unit:
  # 	Unit is derived from base-Unit [acyclic, intransitive];
  # BaseUnit has at most one Exponent;

  # FrequencyConstraint = subtype of PresenceConstraint;

  # MandatoryConstraint = subtype of PresenceConstraint;

  # RoleInSequence = entity known by RoleSequence and Ordinal:
  # 	Role is in RoleSequence in at most one Ordinal place,
  # 	RoleSequence includes at most one Role in Ordinal place,
  # 	each RoleSequence includes some Role in some Ordinal place,
  # 	Role has Ordinal place in RoleSequence;
  # RoleInSequence has at most one leading-Adjective;
  # RoleInSequence has at most one trailing-Adjective;

  # SetComparisonConstraint = subtype of SetConstraint;
  # SetComparisonConstraintCoversRoleSequence = SetComparisonConstraint covers at least one RoleSequence,
  # 	each SetComparisonConstraint covers some RoleSequence;

  # SetEqualityConstraint = subtype of SetComparisonConstraint;

  # SetExclusionConstraint = subtype of SetComparisonConstraint;
  # SetExclusionConstraint is mandatory;

  # Alias = subtype of Feature;

  # Concept = subtype of Feature;
  # Instance is of exactly one Concept;

  # EntityType = subtype of Concept;
  # EntityType is independent;
  # EntityType is personal;
  # EntityType nests at most one FactType,
  # 	FactType is nested as at most one EntityType;

  # Import = entity known by imported-Vocabulary and Vocabulary:
  # 	Vocabulary imports imported-Vocabulary [acyclic];
  # Correspondence = in Import imported-Feature corresponds to at most one local-Feature;

  # Population = entity known by Vocabulary and Name:
  # 	Vocabulary includes Population,
  # 	Population belongs to at most one Vocabulary,
  # 	Population has exactly one Name,
  # 	Name is of Population;
  # Population includes Instance,
  # 	Instance belongs to exactly one Population;
  # Population includes RoleValue,
  # 	RoleValue belongs to exactly one Population;
  # Population includes Fact,
  # 	Fact belongs to exactly one Population;

  # RoleName = subtype of Feature;
  # Role has at most one RoleName,
  # 	RoleName is name of at least one Role,
  # 	each RoleName is name of some Role;

  # TypeInheritance = subtype of FactType known by EntityType and super-EntityType:
  # 	super-EntityType is supertype of EntityType [acyclic],
  # 	EntityType is subtype of super-EntityType;
  # TypeInheritance defines primary supertype;

  # ValueType = subtype of Concept;
  # ValueType is subtype of at most one ValueType [acyclic],
  # 	ValueType is supertype of ValueType;
  # ValueType has at most one Length,
  # 	Length is of ValueType;
  # ValueType has at most one Scale,
  # 	Scale is of ValueType;
  # ValueType has at most one ValueRestriction;
  # ValueType is of at most one Unit;

  end
