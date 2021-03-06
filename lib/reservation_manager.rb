require_relative "room"
require_relative "reservation"
require "pry"

module Hotel
  class ReservationManager
    attr_reader :rooms, :reservations

    def initialize
      @rooms = (1..20).map { |num| Hotel::Room.new(number: num) }
      @reservations = []
    end

    # creates a reservation for first available room if there are any available
    def request_reservation(check_in, check_out, block_name: nil, booking_name:, discount: nil)
      # checks for available rooms
      rooms = available_rooms(check_in, check_out)

      # raises an ArgumentError if no rooms are available
      raise ArgumentError, "No available rooms" if rooms.length == 0

      # creates a reservation
      reservation = Hotel::Reservation.new(check_in: check_in,
                                           check_out: check_out,
                                           room: rooms.first,
                                           block_name: block_name,
                                           booking_name: booking_name,
                                           discount: discount)

      # adds reservation to list of all reservations
      reservations << reservation

      # add reservation to corresponding room
      rooms.first.add_reservation(reservation)
      return reservation
    end

    # returns a list of all reservations for a given date
    def reservations_by_date(date)
      reservations.find_all { |reservation| reservation.all_dates.include?(Date.parse(date)) }
    end

    # returns a list of all available rooms for a given date range
    def available_rooms(check_in, check_out)
      check_in = Date.parse(check_in)
      check_out = Date.parse(check_out)

      if check_in == check_out
        booking_dates = [check_in]
      else
        booking_dates = (check_in..check_out).to_a
      end

      # returns a list of all rooms, if no reservations have been made
      return rooms if reservations.empty?

      available = []
      availability = "yes"

      # searches through each room's reservation dates and if they don't include
      # any of the dates being inquired about adds the room to the available
      # list
      rooms.each do |room|
        room.reservations.each do |reservation|
          reservation.all_dates.each do |date|
            availability = "no" if booking_dates.include?(date)
          end
        end
        available << room if availability == "yes"
        availability = "yes"
      end

      return available
    end

    # creates a block reservation
    def request_block(check_in:, check_out:, number_of_rooms:, discount:, name:)
      # raises an ArgumentError if invalid amount of rooms are entered for a block
      if number_of_rooms > 5 || number_of_rooms < 2
        raise ArgumentError, "A block cannot have more than 5 rooms"
      end

      # raises an argument error if there aren't enough available rooms
      if available_rooms(check_in, check_out).length < number_of_rooms
        raise ArgumentError, "Not enough available rooms for block"
      end

      number_of_rooms.times do
        block_reservation = request_reservation(check_in,
                                                check_out,
                                                block_name: name,
                                                booking_name: nil,
                                                discount: discount)
      end
    end

    # returns all available reservations for rooms in a block
    def available_rooms_in_block(block_name:)
      available = reservations.find_all do |reservation|
        reservation.block_name == block_name && reservation.booking_name == nil
      end

      return available
    end

    # creates a reservation within a block
    def request_reservation_from_block(block_name:, booking_name:)
      available = available_rooms_in_block(block_name: block_name)

      raise ArgumentError, "No available rooms remaining in block" if available.length == 0

      reservation = available.first
      reservation.change_booking_name(booking_name: booking_name)
      return reservation
    end
  end
end
