package aurora {
  public class DataError extends Error {
    public function DataError(message:String, errorID:int) {
      super(message, errorID);
    }
  }
}
