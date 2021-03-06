require "double_or_nothing"

class CalculationsController < ApplicationController

  def new
    @calculation = Calculation.new
  end

  def create
    calculator = DoubleOrNothing::Calculator.new(person_one, person_two)

    @eldest_birthday = eldest
    @youngest_birthday = youngest
    @calculated_date = calculator.call
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
    birthdays.sort.first
  end

  def youngest
    birthdays.sort.last
  end

  def birthdays
    calculation_params.slice(:birthday_one, :birthday_two).values.map {|b|
      Date.parse(b)
    }
  end

end
