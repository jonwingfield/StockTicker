class Stock extends Backbone.Model
	idAttribute: 'symbol'

	initialize: (object, options) ->
		object.price = 15.223

class StockCollection extends Backbone.Collection 
	model: Stock

class StockListView extends Backbone.View
	initialize: ->
		@collection.bind 'add', @addItem, this
		@collection.bind 'remove', @render, this
		@template = _.template($('#itemTemplate').html())

	addItem: (model) ->
		newItem = @template(model.toJSON())
		newItem = $(newItem)
		$(newItem).find('button.remove').click =>
			@collection.remove(model)
		@$el.append(newItem)

	render: ->
		@$el.empty()
		@collection.each (item) => @addItem(item)		

class TickerView extends Backbone.View
	events:
		"click #addSymbolButton": 	"addSymbol"

	initialize: ->
		@collection or= new StockCollection
		@listView = new StockListView 
			el: @$('#portfolio')
			collection: @collection
		console.log @collection

	render: ->
		@listView.render()

	addSymbol: (e) ->
		symbol = @$('#theSymbol').val()
		@collection.add(symbol: symbol)

window.App or= {}
window.App.TickerView = TickerView
window.App.StockCollection = StockCollection