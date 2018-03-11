-- Generated by protobuf; do not edit
local module = {}
local protobuf = require 'protobuf'

module.PERSON = protobuf.Descriptor()
module.PERSON_PHONENUMBER = protobuf.Descriptor()
module.PERSON_PHONENUMBER_NUMBER_FIELD = protobuf.FieldDescriptor()
module.PERSON_PHONENUMBER_TYPE_FIELD = protobuf.FieldDescriptor()
module.PERSON_PHONETYPE = protobuf.EnumDescriptor()
module.PERSON_PHONETYPE_MOBILE_ENUM = protobuf.EnumValueDescriptor()
module.PERSON_PHONETYPE_HOME_ENUM = protobuf.EnumValueDescriptor()
module.PERSON_PHONETYPE_WORK_ENUM = protobuf.EnumValueDescriptor()
module.PERSON_NAME_FIELD = protobuf.FieldDescriptor()
module.PERSON_ID_FIELD = protobuf.FieldDescriptor()
module.PERSON_EMAIL_FIELD = protobuf.FieldDescriptor()
module.PERSON_PHONES_FIELD = protobuf.FieldDescriptor()
module.ADDRESSBOOK = protobuf.Descriptor()
module.ADDRESSBOOK_PEOPLE_FIELD = protobuf.FieldDescriptor()

module.PERSON_PHONENUMBER_NUMBER_FIELD.name = 'number'
module.PERSON_PHONENUMBER_NUMBER_FIELD.full_name = '.tutorial.Person.PhoneNumber.number'
module.PERSON_PHONENUMBER_NUMBER_FIELD.number = 1
module.PERSON_PHONENUMBER_NUMBER_FIELD.index = 0
module.PERSON_PHONENUMBER_NUMBER_FIELD.label = 2
module.PERSON_PHONENUMBER_NUMBER_FIELD.has_default_value = false
module.PERSON_PHONENUMBER_NUMBER_FIELD.default_value = ''
module.PERSON_PHONENUMBER_NUMBER_FIELD.type = 9
module.PERSON_PHONENUMBER_NUMBER_FIELD.cpp_type = 9

module.PERSON_PHONENUMBER_TYPE_FIELD.name = 'type'
module.PERSON_PHONENUMBER_TYPE_FIELD.full_name = '.tutorial.Person.PhoneNumber.type'
module.PERSON_PHONENUMBER_TYPE_FIELD.number = 2
module.PERSON_PHONENUMBER_TYPE_FIELD.index = 1
module.PERSON_PHONENUMBER_TYPE_FIELD.label = 1
module.PERSON_PHONENUMBER_TYPE_FIELD.has_default_value = true
module.PERSON_PHONENUMBER_TYPE_FIELD.default_value = HOME
module.PERSON_PHONENUMBER_TYPE_FIELD.enum_type = module.PERSON_PHONETYPE
module.PERSON_PHONENUMBER_TYPE_FIELD.type = 14
module.PERSON_PHONENUMBER_TYPE_FIELD.cpp_type = 8

module.PERSON_PHONENUMBER.name = 'PhoneNumber'
module.PERSON_PHONENUMBER.full_name = '.tutorial.Person.PhoneNumber'
module.PERSON_PHONENUMBER.nested_types = {}
module.PERSON_PHONENUMBER.enum_types = {}
module.PERSON_PHONENUMBER.fields = {module.PERSON_PHONENUMBER_NUMBER_FIELD, module.PERSON_PHONENUMBER_TYPE_FIELD}
module.PERSON_PHONENUMBER.is_extendable = false
module.PERSON_PHONENUMBER.extensions = {}
module.PERSON_PHONENUMBER.containing_type = PERSON
module.PERSON_PHONETYPE_MOBILE_ENUM.name = 'MOBILE'
module.PERSON_PHONETYPE_MOBILE_ENUM.index = 0
module.PERSON_PHONETYPE_MOBILE_ENUM.number = 0
module.PERSON_PHONETYPE_HOME_ENUM.name = 'HOME'
module.PERSON_PHONETYPE_HOME_ENUM.index = 1
module.PERSON_PHONETYPE_HOME_ENUM.number = 1
module.PERSON_PHONETYPE_WORK_ENUM.name = 'WORK'
module.PERSON_PHONETYPE_WORK_ENUM.index = 2
module.PERSON_PHONETYPE_WORK_ENUM.number = 2
module.PERSON_PHONETYPE.name = 'PhoneType'
module.PERSON_PHONETYPE.full_name = '.tutorial.Person.PhoneType'
module.PERSON_PHONETYPE.values = {PERSON_PHONETYPE_MOBILE_ENUM,PERSON_PHONETYPE_HOME_ENUM,PERSON_PHONETYPE_WORK_ENUM}
module.PERSON_NAME_FIELD.name = 'name'
module.PERSON_NAME_FIELD.full_name = '.tutorial.Person.name'
module.PERSON_NAME_FIELD.number = 1
module.PERSON_NAME_FIELD.index = 0
module.PERSON_NAME_FIELD.label = 2
module.PERSON_NAME_FIELD.has_default_value = false
module.PERSON_NAME_FIELD.default_value = ''
module.PERSON_NAME_FIELD.type = 9
module.PERSON_NAME_FIELD.cpp_type = 9

module.PERSON_ID_FIELD.name = 'id'
module.PERSON_ID_FIELD.full_name = '.tutorial.Person.id'
module.PERSON_ID_FIELD.number = 2
module.PERSON_ID_FIELD.index = 1
module.PERSON_ID_FIELD.label = 2
module.PERSON_ID_FIELD.has_default_value = false
module.PERSON_ID_FIELD.default_value = 0
module.PERSON_ID_FIELD.type = 5
module.PERSON_ID_FIELD.cpp_type = 1

module.PERSON_EMAIL_FIELD.name = 'email'
module.PERSON_EMAIL_FIELD.full_name = '.tutorial.Person.email'
module.PERSON_EMAIL_FIELD.number = 3
module.PERSON_EMAIL_FIELD.index = 2
module.PERSON_EMAIL_FIELD.label = 1
module.PERSON_EMAIL_FIELD.has_default_value = false
module.PERSON_EMAIL_FIELD.default_value = ''
module.PERSON_EMAIL_FIELD.type = 9
module.PERSON_EMAIL_FIELD.cpp_type = 9

module.PERSON_PHONES_FIELD.name = 'phones'
module.PERSON_PHONES_FIELD.full_name = '.tutorial.Person.phones'
module.PERSON_PHONES_FIELD.number = 4
module.PERSON_PHONES_FIELD.index = 3
module.PERSON_PHONES_FIELD.label = 3
module.PERSON_PHONES_FIELD.has_default_value = false
module.PERSON_PHONES_FIELD.default_value = {}
module.PERSON_PHONES_FIELD.message_type = module.PERSON_PHONENUMBER
module.PERSON_PHONES_FIELD.type = 11
module.PERSON_PHONES_FIELD.cpp_type = 10

module.PERSON.name = 'Person'
module.PERSON.full_name = '.tutorial.Person'
module.PERSON.nested_types = {module.PERSON_PHONENUMBER}
module.PERSON.enum_types = {module.PERSON_PHONETYPE}
module.PERSON.fields = {module.PERSON_NAME_FIELD, module.PERSON_ID_FIELD, module.PERSON_EMAIL_FIELD, module.PERSON_PHONES_FIELD}
module.PERSON.is_extendable = false
module.PERSON.extensions = {}
module.ADDRESSBOOK_PEOPLE_FIELD.name = 'people'
module.ADDRESSBOOK_PEOPLE_FIELD.full_name = '.tutorial.AddressBook.people'
module.ADDRESSBOOK_PEOPLE_FIELD.number = 1
module.ADDRESSBOOK_PEOPLE_FIELD.index = 0
module.ADDRESSBOOK_PEOPLE_FIELD.label = 3
module.ADDRESSBOOK_PEOPLE_FIELD.has_default_value = false
module.ADDRESSBOOK_PEOPLE_FIELD.default_value = {}
module.ADDRESSBOOK_PEOPLE_FIELD.message_type = module.PERSON
module.ADDRESSBOOK_PEOPLE_FIELD.type = 11
module.ADDRESSBOOK_PEOPLE_FIELD.cpp_type = 10

module.ADDRESSBOOK.name = 'AddressBook'
module.ADDRESSBOOK.full_name = '.tutorial.AddressBook'
module.ADDRESSBOOK.nested_types = {}
module.ADDRESSBOOK.enum_types = {}
module.ADDRESSBOOK.fields = {module.ADDRESSBOOK_PEOPLE_FIELD}
module.ADDRESSBOOK.is_extendable = false
module.ADDRESSBOOK.extensions = {}

module.AddressBook = protobuf.Message(module.ADDRESSBOOK)
module.Person = protobuf.Message(module.PERSON)
module.Person.PhoneNumber = protobuf.Message(module.PERSON_PHONENUMBER)


module.MESSAGE_TYPES = {'Person','AddressBook'}
module.ENUM_TYPES = {}

return module