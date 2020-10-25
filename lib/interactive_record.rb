require_relative "../config/environment.rb"
require 'active_support/inflector'

class InteractiveRecord
    
    def self.table_name
        self.to_s.downcase.pluralize
    end

    def self.column_names
        DB[:conn].results_as_hash = true

        sql = "pragma table_info('#{self.table_name}')"

        DB[:conn].execute(sql).collect{ |row| row["name"] }
    end

    def initialize(object_hash = {})
        object_hash.each do |key, value|
            self.send("#{key}=", value)
        end
    end

    def table_name_for_insert
        self.class.table_name
    end

    def col_names_for_insert
        self.class.column_names.delete_if { |column| column == "id"}.join(", ")
    end

    def values_for_insert
        values = []
        self.class.column_names.each do |column_name|
            values << "'#{send(column_name)}'" unless send(column_name).nil?
        end
        values.join(", ")
    end

    def save
        sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})"
        DB[:conn].execute(sql)
        @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
    end

    def self.find_by_name(name)
        sql = "SELECT * from #{table_name} WHERE name = ?"
        x = DB[:conn].execute(sql, name)
    end

    def self.find_by(attribute)
        att_name = attribute.first[0].to_s
        att = attribute.first[1].to_s
        sql = "SELECT * from #{table_name} WHERE #{att_name} = ?"
        DB[:conn].execute(sql, att)
    end

end