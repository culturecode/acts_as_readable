`createdb acts_as_readable_test`
require 'spec_helper'

describe 'acts_as_readable' do
  shared_examples_for 'a readable class' do |readable_class, queryable_class|
    before(:each) do
      @readable = readable_class.create
      @queryable = @readable.becomes!(queryable_class)
      @user = User.create
    end

    describe '::unread_by!' do
      it "clears all readings with this readable class for the given user" do
        readable_class.read_by! @user
        expect { readable_class.unread_by! @user }
          .to change { queryable_class.unread_by(@user) }.to include(@queryable)
      end
    end

    describe "the unread scope" do
      it "should not return records explicitly marked as read" do
        @readable.read_by! @user
        expect(queryable_class.unread_by(@user)).not_to include(@queryable)
      end

      it "should return records without readings if the user hasn't 'read all'" do
        expect(queryable_class.unread_by(@user)).to include(@queryable)
      end

      it "should return records explicitly marked as unread if the user hasn't 'read all'" do
        @readable.unread_by! @user
        expect(queryable_class.unread_by(@user)).to include(@queryable)
      end

      it "should return records explicitly marked as unread if the user has 'read all' before the record was marked unread" do
        readable_class.read_by! @user
        @readable.unread_by! @user
        expect(queryable_class.unread_by(@user)).to include(@queryable)
      end

      it "should return records explicitly marked as unread after the user 'read all'" do
        @readable.read_by! @user
        readable_class.read_by! @user
        @readable.unread_by! @user
        expect(queryable_class.unread_by(@user)).to include(@queryable)
      end

      it "should not return records explicitly marked as unread if the user has 'read all' after the record was marked unread" do
        @readable.unread_by! @user
        readable_class.read_by! @user
        expect(queryable_class.unread_by(@user)).not_to include(@queryable)
      end

      it "should not return records that have been updated since they were last read" do
        @readable.read_by! @user
        @readable.touch
        expect(queryable_class.unread_by(@user)).not_to include(@queryable)
      end

      it "should return records that have been updated since they were last unread" do
        @readable.unread_by! @user
        @readable.touch
        expect(queryable_class.unread_by(@user)).to include(@queryable)
      end
    end

    describe "the read scope" do
      it "should not return records without readings if the user has not 'read all'" do
        expect(queryable_class.read_by(@user)).not_to include(@queryable)
      end

      it "should return records without readings if the user has 'read all' since the last time the record was updated" do
        readable_class.read_by! @user
        expect(queryable_class.read_by(@user)).to include(@queryable)
      end

      it "should return records explicitly marked as read if the user hasn't 'read all'" do
        @readable.read_by! @user
        expect(queryable_class.read_by(@user)).to include(@queryable)
      end

      it "should return records explicitly marked as read if the user has 'read all' before the record was marked read" do
        readable_class.read_by! @user
        @readable.read_by! @user
        expect(queryable_class.read_by(@user)).to include(@queryable)
      end

      it "should not return records explicitly marked as unread after the user 'read all'" do
        @readable.read_by! @user
        readable_class.read_by! @user
        @readable.unread_by! @user
        expect(queryable_class.read_by(@user)).not_to include(@queryable)
      end

      it "should return records explicitly marked as unread if the user has 'read all' after the record was marked unread" do
        @readable.unread_by! @user
        readable_class.read_by! @user
        expect(queryable_class.read_by(@user)).to include(@queryable)
      end

      it "should return records that have been updated since they were last read" do
        @readable.read_by! @user
        @readable.touch
        expect(queryable_class.read_by(@user)).to include(@queryable)
      end
    end

    describe "the latest_update_read_by scope" do
      it "should return records without readings if the user has 'read all' since the last time the record was updated" do
        readable_class.read_by! @user
        expect(queryable_class.latest_update_read_by(@user)).to include(@queryable)
      end

      it "should return records explicitly marked as read if the user hasn't 'read all'" do
        @readable.read_by! @user
        expect(queryable_class.latest_update_read_by(@user)).to include(@queryable)
      end

      it "should return records explicitly marked as read if the user has 'read all' before the record was marked unread" do
        readable_class.read_by! @user
        @readable.read_by! @user
        expect(queryable_class.latest_update_read_by(@user)).to include(@queryable)
      end

      it "should return records explicitly marked as unread if the user has 'read all' after the record was marked unread" do
        @readable.unread_by! @user
        readable_class.read_by! @user
        expect(queryable_class.latest_update_read_by(@user)).to include(@queryable)
      end

      it "should not return records that have been updated since they were last read" do
        @readable.read_by! @user
        @readable.touch
        expect(queryable_class.latest_update_read_by(@user)).not_to include(@queryable)
      end

      it "should return records updated after being read after a bulk read_by" do
        @readable.read_by! @user
        @readable.touch
        readable_class.read_by! @user
        expect(queryable_class.latest_update_read_by(@user)).to include(@queryable)
      end
    end

    describe "the latest_update_unread_by scope" do
      it "should not return records explicitly marked as read" do
        @readable.read_by! @user
        expect(queryable_class.latest_update_unread_by(@user)).not_to include(@queryable)
      end

      it "should return records without readings if the user hasn't 'read all'" do
        expect(queryable_class.latest_update_unread_by(@user)).to include(@queryable)
      end

      it "should return records explicitly marked as unread if the user hasn't 'read all'" do
        @readable.unread_by! @user
        expect(queryable_class.latest_update_unread_by(@user)).to include(@queryable)
      end

      it "should return records explicitly marked as unread if the user has 'read all' before the record was marked unread" do
        readable_class.read_by! @user
        @readable.unread_by! @user
        expect(queryable_class.latest_update_unread_by(@user)).to include(@queryable)
      end

      it "should not return records explicitly marked as unread if the user has 'read all' after the record was marked unread" do
        @readable.unread_by! @user
        readable_class.read_by! @user
        expect(queryable_class.latest_update_unread_by(@user)).not_to include(@queryable)
      end

      it "should return records that have been updated since they were last read" do
        @readable.read_by! @user
        @readable.touch
        expect(queryable_class.latest_update_unread_by(@user)).to include(@queryable)
      end
    end

    describe "when checking a specific record for read_by?" do
      it "should return true if the record hasn't explicitly been read, but the user has 'read all' since the record was created" do
        readable_class.read_by! @user
        expect(@queryable.read_by?(@user)).to be_truthy
      end

      it "should return true if the record hasn't explicitly been read and the user has 'read all' since the record was created but not since it was updated" do
        readable_class.read_by! @user
        @readable.touch
        expect(@queryable.read_by?(@user)).to be_truthy
      end

      it "should return true if the record has been explicitly marked as read and the user hasn't 'read all'" do
        @readable.read_by! @user
        expect(@queryable.read_by?(@user)).to be_truthy
      end

      it "should return false if the user 'read all' before and then marked the record as unread" do
        readable_class.read_by! @user
        @readable.unread_by! @user
        expect(@queryable.read_by?(@user)).to be_falsey
      end

      it "should return true if the user has explicitly marked it as unread and then 'reads all'" do
        @readable.unread_by! @user
        readable_class.read_by! @user
        expect(@queryable.read_by?(@user)).to be_truthy
      end
    end

    describe "when checking a specific record for latest_update_read_by?" do
      it "should return true if the record hasn't explicitly been read, but the user has 'read all' since the record was updated" do
        readable_class.read_by! @user
        expect(@queryable.latest_update_read_by?(@user)).to be_truthy
      end

      it "should return false if the record hasn't explicitly been read and the user has 'read all' since the record was created but not since it was updated" do
        readable_class.read_by! @user
        @readable.touch
        expect(@queryable.latest_update_read_by?(@user)).to be_falsey
      end

      it "should return true if the record has been explicitly marked as read and the user hasn't 'read all'" do
        @readable.read_by! @user
        expect(@queryable.latest_update_read_by?(@user)).to be_truthy
      end

      it "should return false if the user 'read all' before and then marked the record as unread" do
        readable_class.read_by! @user
        @readable.unread_by! @user
        expect(@queryable.latest_update_read_by?(@user)).to be_falsey
      end

      it "should return true if the user has explicitly marked it as unread and then 'reads all'" do
        @readable.unread_by! @user
        readable_class.read_by! @user
        expect(@queryable.latest_update_read_by?(@user)).to be_truthy
      end

      it "should return false if the user 'read all' before and then marked the record as unread using cached readings" do
        readable_class.read_by! @user
        @readable.unread_by! @user
        readable_class.cache_readings_for([@readable], @user)
        expect(@queryable.latest_update_read_by?(@user)).to be_falsey
      end
    end
  end

  context 'the readable is a base class' do
    it_behaves_like 'a readable class', Comment, Comment
  end

  context 'when reading an STI record' do
    it_behaves_like 'a readable class', PrivateComment, PrivateComment
  end

  context 'when reading an STI record and querying against the base class record' do
    it_behaves_like 'a readable class', PrivateComment, Comment
  end
end
`dropdb acts_as_readable_test`
