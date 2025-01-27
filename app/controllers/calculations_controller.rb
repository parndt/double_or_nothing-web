require "double_or_nothing"

class CalculationsController < ApplicationController
  def new
    @calculation = Calculation.new
  end

  def create
    @eldest_birthday = birthdays.min
    @youngest_birthday = birthdays.max
    @calculated_date = calculator.call
  end

  private def calculator = DoubleOrNothing::Calculator.new(person_one, person_two)

  private def calculation_params = params.require(:calculation).permit(:birthday_one, :birthday_two)

  private def person_one = DoubleOrNothing::Person.new(calculation_params[:birthday_one])

  private def person_two = DoubleOrNothing::Person.new(calculation_params[:birthday_two])

  private def birthdays
    calculation_params
      .slice(:birthday_one, :birthday_two)
      .values
      .map(&Date.method(:parse))
  end
end
