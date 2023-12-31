class Api::V1::LineFoodsController < ApplicationController
  before_action :set_food, only: %i[create replace]

  def index
    line_foods = LineFood.active
    if line_foods.exists?
      render json: {
        line_food_ids: line_foods.map { |line_food| line_food.id },
        restaurant: line_foods[0].restaurant,
        food_ids: line_foods.map { |line_food| line_food.food.id },
        count: line_foods.sum { |line_food| line_food[:count] },
        each_count: line_foods.map { |line_food| line_food[:count] },
        amount: line_foods.sum { |line_food| line_food.total_amount },
      }, status: :ok
    else
      render json: {}, status: :no_content
    end
  end

  def create
    if LineFood.active.other_restaurant(@ordered_food.restaurant.id).exists?
      # 他店舗の仮注文がすでに存在している場合の処理
      return render json: {
        existing_restaurant: LineFood.other_restaurant(@ordered_food.restaurant.id).first.restaurant.name,
        new_restaurant: Food.find(params[:food_id]).restaurant.name
      }, status: :not_acceptable
    end

    set_line_food(@ordered_food)

    if @line_food.save
      render json: {
        line_food: @line_food
      }, status: :created # 201
    else
      render json: {}, status: :internal_server_error # 500
    end
  end

  def replace
    LineFood.active.other_restaurant(@ordered_food.restaurant.id).each do |line_food|
      line_food.update_attribute(:active, false)
    end

    set_line_food(@ordered_food)

    if @line_food.save
      render json: {
        line_food: @line_food
      }, status: :created
    else
      render json: {}, status: :internal_server_error
    end
  end

  private
  def set_food
    @ordered_food = Food.find(params[:food_id])
  end

  def set_line_food(ordered_food)
    if ordered_food.line_food.present?
      # 仮注文がすでに存在している場合の処理
      @line_food = ordered_food.line_food
      @line_food.attributes = {
        count: ordered_food.line_food.count + params[:count],
        active: true
      }
    else
      # 仮注文が存在しない場合の処理
      @line_food = ordered_food.build_line_food(
        count: params[:count],
        restaurant: ordered_food.restaurant,
        active: true
      )
    end
  end
end





