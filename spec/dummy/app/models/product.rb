class Product < ActiveRecord::Base
  acts_as_superclass as: 'producible'

  belongs_to :store

  validates_presence_of :name, :price

  def parent_method
    "#{name} - #{price}"
  end

  def dummy_raise_method(obj)
    obj.dummy
  end
end
