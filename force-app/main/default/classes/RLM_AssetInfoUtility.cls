public class RLM_AssetInfoUtility {

    @InvocableMethod (label='Calculate Asset Info' description='Returns Asset Renewal Info')
    public static void calculateAssetRenewInfo(List<CreateAssetOrderEvent> assetOrderCreationEvents){
        CreateAssetOrderEvent assetOrderCreationEvent = assetOrderCreationEvents.get(0);

        List<CreateAssetOrderDtlEvent> assetDetailEvents = assetOrderCreationEvent.AssetDetails;

        List<Asset> assetsToUpdate = new List<Asset>();

        for(CreateAssetOrderDtlEvent assetDetailEvent: assetDetailEvents){
            OrderItem oi = [SELECT Id, ServiceDate, EndDate, OrderAction.Type,
                                    ProductSellingModel.PricingTermUnit, Product2.Name
                            FROM OrderItem
                            WHERE Id =: assetDetailEvent.OrderItemId].get(0);
            
            system.debug('Processing Order Item ' + oi.Id + ' for Product' + oi.Product2.Name);

            if(oi.OrderAction.Type == 'Add'){
                Asset assetToUpdate = new Asset();

                assetToUpdate.Id = assetDetailEvent.AssetId;

                if(oi.ProductSellingModel.PricingTermUnit == 'Months'){
                    assetToUpdate.RenewalTerm = oi.ServiceDate.monthsBetween(oi.EndDate);
                    assetToUpdate.RenewalTermUnit = oi.ProductSellingModel.PricingTermUnit;
                }else{
                    assetToUpdate.RenewalTerm = ((oi.ServiceDate.monthsBetween(oi.EndDate))/12);
                    assetToUpdate.RenewalTermUnit = 'Annual';
                }
                    
                assetToUpdate.PricingSource = 'LastTransaction';

                assetsToUpdate.add(assetToUpdate);
            }else{
                Asset assetToUpdate = new Asset();

                List<AssetContractRelationship> acrs = [SELECT Id, AssetId, Contract.ContractTerm
                                                            FROM AssetContractRelationship
                                                            WHERE AssetId =: assetDetailEvent.AssetId];
    
                if(acrs.size()>0){
                    AssetContractRelationship acr = acrs.get(0);

                    assetToUpdate.Id = assetDetailEvent.AssetId;
                    assetToUpdate.RenewalTermUnit = 'Months';
                    assetToUpdate.RenewalTerm = acr.Contract.ContractTerm;
                    assetToUpdate.PricingSource = 'PriceBookListPrice';
                }
            }            
        }

        upsert assetsToUpdate;
    }

}