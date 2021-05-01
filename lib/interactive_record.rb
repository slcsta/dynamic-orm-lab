require 'pry'
require_relative "../config/environment.rb"
require 'active_support/inflector'

class InteractiveRecord

    def self.table_name
        self.to_s.downcase.pluralize
    end

    def self.column_names
        # hash of column names
        # return column names as an array of strings
        DB[:conn].results_as_hash = true

        sql = "PRAGMA table_info('#{table_name}')" # gets hash with info requested
        table_info = DB[:conn].execute(sql)
        column_names = []
        
        # iterate over the array of hashes
        table_info.each do |column|
            column_names << column["name"] # gets the value for the key "name"
        end
        column_names.compact # .compact gets rid of nulls
    end

    def initialize(options={}) 
    # pass in a hash "options" as arg - then mass assignment
        options.each do |property, value|
            self.send("#{property}=", value)
        end
    end

    def table_name_for_insert 
        # returns the table name when called on an instance of the student
        self.class.table_name
    end

    def col_names_for_insert
        # returns the column names when called on an instance of the student
        self.class.column_names.delete_if {|col| col == "id"}.join(", ")
    end

    def values_for_insert
        # inserts data into db
        # formats column names to be used in SQL statement
        # use column_names array, iterate over it to get attribute names
        # use attribute = method w/send to assign value
        # get value for each attribute name
        values = []
        self.class.column_names.each do |col_name|
            values << "'#{send(col_name)}'" unless send(col_name).nil?
        end
        values.join(", ")
    end

    def save
        # insert data into the db then saves the student to the db
        DB[:conn].execute("INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})")
        
        self.id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
    end

    def self.find_by_name(name)
        # executes SQL to find row by name passed is as arg to the method
        # where name = ?
        sql = "SELECT * FROM #{self.table_name} WHERE name = ?"
        row = DB[:conn].execute(sql, name)
    end
          


    def self.find_by(attribute)
        # executes SQL to find row by attribute passed in as argument to the method
        # WHERE name = ? or grade = ? or id = ?
        # attribute is a hash with a key/value pair
        attribute_key = attribute.keys.join()
        attribute_value = attribute.values.first
        sql = <<-SQL
            SELECT * FROM #{self.table_name} 
            WHERE #{attribute_key} = "#{attribute_value}"
            LIMIT 1
        SQL

        row = DB[:conn].execute(sql)
    end
end