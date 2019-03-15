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

    def request_reservation(check_in, check_out, block_name: nil, booking_name:, discount: nil)
      rooms = available_rooms(check_in, check_out)

      raise ArgumentError, "No available rooms" if rooms.length == 0

      reservation = Hotel::Reservation.new(check_in: check_in,
                                           check_out: check_out,
                                           room: rooms.first,
                                           block_name: block_name,
                                           booking_name: booking_name,
                                           discount: discount)

      reservations << reservation
      # could get rid of this method...
      rooms.first.add_reservation(reservation)
      return reservation
    end

    def reservations_by_date(date)
      reservations.find_all { |reservation| reservation.all_dates.include?(Date.parse(date)) }
    end

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

    # can I combine this method with request_reservation?
    def request_block(check_in:, check_out:, number_of_rooms:, discount:, name:)
      if number_of_rooms > 5 || number_of_rooms < 2
        raise ArgumentError, "A block cannot have more than 5 rooms"
      end
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

    def available_rooms_in_block(block_name:)
      available = reservations.find_all do |reservation|
        reservation.block_name == block_name && reservation.booking_name == nil
      end

      return available
    end

    # def request_reservation_from_block(block_name:, booking_name:)
    #   block_reservations = reservations.find_all { |reservation| reservation.block_name == block_name }

    #   block_reservations.first.booking_name = booking_name
    #   block_reservation.booking_name = booking_name
    # end
  end
end
