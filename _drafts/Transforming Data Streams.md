That is: 

```
<Output> 	::=  <Header> { <TransactionGroup> | <NoTransactionsMessage> | <NotFoundMessage>}
<TransactionGroup> ::= { <DateGroup> }0,n <Footer>
<Header> 	::= DataSetName
<DateGroup> ::= <Subheader> { <Transaction> }0,n <Subfooter>
<Subheader> ::= Date
<Subfooter> ::= Blank
<Transaction> ::= Description CreditAmount | DebitAmount
<Footer> 	::= Total 
```

