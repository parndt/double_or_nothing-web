require "double_or_nothing"

class CalculationsController < ApplicationController

  def new
    @calculation = Calculation.new
  end

  def create
    calculator = DoubleOrNothing::Calculator.new(person_one, person_two)

    render :text => "The person with the birthday '#{eldest}'
      will be twice the age of the person with birthday '#{youngest}'
      at '#{calculator.call}'."
  end

  private
  def calculation_params
    params.require(:calculation).permit(:birthday_one, :birthday_two)
  end

  def person_one
    DoubleOrNothing::Person.new(calculation_params[:birthday_one])
  end

  def person_two
    DoubleOrNothing::Person.new(calculation_params[:birthday_two])
  end

  def eldest
    calculation_params.slice(:birthday_one, :birthday_two).values.sort.last
  end

  def youngest
    calculation_params.slice(:birthday_one, :birthday_two).values.sort.first
  end

end
