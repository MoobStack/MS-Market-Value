local fresh,truth,equal=...
local w,A=fresh();w:load()
GetInboxNumItems=function()return 500 end
GetInboxInvoiceInfo=function(index)return "seller","Invoice item",nil,index,0,0,0,0,0,0,1,false end
GetInboxHeaderInfo=function()return nil,nil,nil,nil,0,0,30 end
w:event("MAIL_SHOW");debugprofilestop=function()return os.clock()*1000 end
local steps,maxStep=0,0;local start=os.clock()
while A.Transactions.mailDirty or A.Transactions.mailJob do
    local step=os.clock();A.Transactions.Tick();maxStep=math.max(maxStep,(os.clock()-step)*1000)
    w.mono,w.wall=w.mono+.25,w.wall+.25;steps=steps+1;truth(steps<1000)
end
local mailCPU=(os.clock()-start)*1000
equal(#A.Ledger.Records(),500);equal(A.Ledger.Summary().flow,125250)
for index=1,9500 do truth(A.Ledger.Record({kind=index%2==0 and"buy"or"sale",name="Benchmark item",quantity=1,amount=1000,fee=50,cost=100}))end
equal(#A.Ledger.Records(),10000)
local filter=A.Ledger.Range("today");filter.kind="sale"
local begin=os.clock();local rows=A.Ledger.View(filter);local sums=A.Ledger.Summary(filter)
for _=1,100 do equal(A.Ledger.View(filter),rows);equal(A.Ledger.Summary(filter),sums)end
local filterCPU=(os.clock()-begin)*1000
local calls=w.itemCalls or 0;local reads=w.containerReads or 0
for _=1,100 do A.Transactions.Tick()end
equal(w.itemCalls or 0,calls);equal(w.containerReads or 0,reads);equal(w.requests,0)
print(string.format("TRANSACTION_BENCHMARK invoices=500 steps=%d mail_cpu_ms=%.2f max_step_ms=%.2f ledger_entries=10000 cached_filtered_view_cpu_ms=%.2f filtered_entries=%d csv_bytes=%d requests=0",steps,mailCPU,maxStep,filterCPU,#rows,#A.Ledger.CSV()))
