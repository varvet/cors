# encoding: utf-8
require "manifest/rules"
require "manifest/request"

class << Manifest
  def new(&block)
    unless block_given?
      raise ArgumentError, "manifest rules must be specified by a block, no block given"
    end

    rules = Manifest::Rules.new(&block)
    Class.new(Manifest::Request) { @rules = rules }
  end
end
