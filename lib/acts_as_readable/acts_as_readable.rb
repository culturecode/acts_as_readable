module ActsAsReadable
  module ActMethod
    # OPTIONS
    # :cache  => the name under which to cache timestamps for a "mark all as read" action to avoid the need to actually create readings for each record marked as read
    def acts_as_readable(options = {})
      class_attribute :acts_as_readable_options
      self.acts_as_readable_options = options

      User.has_many :readings,  :dependent => :delete_all

      has_many :readings,       :as => :readable, :dependent => :delete_all
      has_many :readers,        lambda { where :readings => {:state => 'read'} }, :through => :readings, :source => :user

      scope :read_by,           lambda {|user| ActsAsReadable::HelperMethods.outer_join_readings(all, user).where(ActsAsReadable::HelperMethods.read_conditions(self, user))}
      scope :unread_by,         lambda {|user| ActsAsReadable::HelperMethods.outer_join_readings(all, user).where(ActsAsReadable::HelperMethods.unread_conditions(self, user))}

      extend ActsAsReadable::ClassMethods
      include ActsAsReadable::InstanceMethods
    end

    def acts_as_reader
      has_many :readings, :dependent => :delete_all
    end
  end

  module HelperMethods
    def self.read_conditions(readable_class, user)
      ["(readable_type IS NULL     AND COALESCE(#{readable_class.table_name}.updated_at < :all_read_at, :true))
     OR (readable_type IS NOT NULL AND COALESCE(readings.updated_at < :all_read_at, :true))
     OR (readings.state = 'read')",
     :all_read_at => all_read_at(readable_class, user), :true => true]
    end

    def self.unread_conditions(readable_class, user)
      # IF there is no reading and it has been updated since we last read all OR there is an unreading and we haven't read all since then
      ["(readings.state IS NULL    AND COALESCE(#{readable_class.table_name}.updated_at > :all_read_at, :true))
     OR (readings.state = 'unread' AND COALESCE(readings.updated_at > :all_read_at, :true))
     OR (readings.state = 'read'   AND COALESCE(#{readable_class.table_name}.updated_at > readings.updated_at, :true))",
     :all_read_at => all_read_at(readable_class, user), :true => true]
    end

    def self.all_read_at(readable_class, user)
      user[readable_class.acts_as_readable_options[:cache]] if readable_class.acts_as_readable_options[:cache]
    end

    def self.outer_join_readings(scope, user)
      scope.joins("LEFT OUTER JOIN readings ON readings.readable_type = '#{scope.model.name}' AND readings.readable_id = #{scope.model.table_name}.id AND readings.user_id = #{user.id}")
    end
  end

  module ClassMethods
    # Find all the readings of the readables by the user in a single SQL query and cache them in the readables for use in the view.
    def cache_readings_for(readables, user)
      readings = []
      Reading.where(:readable_type => name, :readable_id => readables.collect(&:id), :user_id => user.id).each do |reading|
        readings[reading.readable_id] = reading
      end

      for readable in readables
        readable.cached_reading = readings[readable.id] || false
      end

      return readables
    end

    # Mark all records as read by the user
    # If a :cache option has been set in acts_as_readable, a timestamp will be updated on the user instead of creating individual readings for each record
    def read_by!(user)
      if user.has_attribute?(acts_as_readable_options[:cache])
        Reading.where(:user_id => user.id, :readable_type => name).delete_all
        user.update_column(acts_as_readable_options[:cache], Time.now)
      else
        unread_by(user).find_each do |record|
          record.read_by!(user)
        end
      end
    end
  end

  module InstanceMethods
    attr_accessor :cached_reading

    def acts_like_readable?
      true
    end

    def read_by!(user)
      # Find an existing reading and update the record so we can know when the thing was first read, and the last time we read it
      reading = Reading.find_or_initialize_by(:user_id => user.id, :readable_id => self.id, :readable_type => self.class.name)
      reading.updated_at = Time.now # Explicitly set the read time to now in order to force a save in case we haven't changed anything else about the reading
      reading.state = :read
      reading.save!
    rescue ActiveRecord::RecordNotUnique
      # Database-level uniqueness constraint failed.
      return self
    end

    def unread_by!(user)
      reading = Reading.find_or_initialize_by(:user_id => user.id, :readable_id => self.id, :readable_type => self.class.name)
      reading.state = :unread
      reading.save!
    end

    def read_by?(user)
      if cached_reading
        cached_reading.read?
      elsif cached_reading == false
        user[acts_as_readable_options[:cache]].to_f > self.created_at.to_f
      elsif readers.loaded?
        readers.include?(user)
      elsif reading = readings.find_by_user_id(user.id)
        reading.read?
      else
        user[acts_as_readable_options[:cache]].to_f > self.created_at.to_f
      end
    end

    # Returns true if the user has read this at least once, but it has been updated since the last reading
    def updated?(user)
      read_by?(user) && !latest_update_read_by?(user)
    end

    def latest_update_read_by?(user)
      if cached_reading
        cached_reading.read? && cached_reading.updated_at > self.updated_at
      elsif cached_reading == false
        user[acts_as_readable_options[:cache]].to_f > self.updated_at.to_f
      elsif reading = readings.find_by_user_id(user.id)
        reading.read? && reading.updated_at > self.updated_at
      else
        user[acts_as_readable_options[:cache]].to_f > self.updated_at.to_f
      end
    end
  end
end
