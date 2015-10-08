# ActiveFacts

* http://dataconstellation.com/ActiveFacts/

## DESCRIPTION

ActiveFacts provides a fact-based semantic modeling language, the
Constellation Query Language (CQL).  CQL combines natural language
verbalisation and formal logic, producing a formal language that
reads like plain English. ActiveFacts converts semantic models from
CQL to relational and object models in SQL, Ruby and other languages.

The generated models are guaranteed congruent, which can eliminate the
object-relational impedance mismatch.  Fact based models are much more
stable under evolving requirements than either relational or
object-oriented models, because they directly express the underlying
conceptual structure as elementary facts, so are not susceptible to
ramifying change in the way those attribute-oriented approaches are.

Semantic modeling is a refinement of fact-based modeling techniques
such as ORM2, NIAM and others. ActiveFacts can convert ORM2 files from
NORMA to CQL. Fact-based modeling is closely related to relational
modeling in the sixth normal form (as Codd intended it!), but the
generated relation schemas are in 5NF, so they don't suffer from 6NF
inefficiency.  The relational models it derives are highly efficient.

## SYNOPSIS:

```
afgen --help
afgen --sql/server myfile.cql
afgen --ruby myfile.cql
afgen --cql myfile.orm
afgen --transform/surrogate --rails/schema myfile.cql
afgen --transform/datavault --sql/server myfile.cql
cql (command-line interpreter, including a query evaluator)
```

## INSTALL:

> sudo gem install activefacts

## STATUS

  * The definition language is complete and the main generators are usable.

  * Arithmetic and aggregate operations in queries are recognised but not compiled.

  * Queries and derived fact types not yet generated to SQL queries or views..

  * The Constellation API is solid; the CQL compiler uses the generated Ruby code extensively

  * Advanced constraint types are mostly ignored by the generators.

## REQUIREMENTS:

 * Treetop parser generator

 * NORMA (see <http://www.ormfoundation.org/files/>), if you want to
   use ORM (needs Visual Studio Pro or Community  edition)
