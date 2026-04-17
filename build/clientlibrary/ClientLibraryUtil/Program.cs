using Newtonsoft.Json;
using System;
using System.Collections.Generic;

namespace ClientLibraryUtil
{
    class Program
    {
        static void Main(string[] args)
        {
            Console.WriteLine("Start to Update Data Extensions");
            if (args.Length != 2)
            {
                Console.WriteLine("Pass the exact arguments to update the JSON");
            }
            else
            {
                var _extensions = args[0].Split(new String[] { ";" }, StringSplitOptions.RemoveEmptyEntries);
                var filePaths = args[1].Split(new String[] { ";" }, StringSplitOptions.RemoveEmptyEntries);
                Dictionary<string, string> extensions = new Dictionary<string, string>();

                if (_extensions.Length > 0)
                {
                    foreach (var item in _extensions)
                    {
                        var extensionInfo = item.Split(new String[] { "=" }, StringSplitOptions.RemoveEmptyEntries);
                        extensions.Add(extensionInfo[0], extensionInfo.Length == 2 ? extensionInfo[1] : string.Empty);
                    }
                }

                if (filePaths.Length == 0 || extensions.Count == 0)
                {
                    Console.WriteLine("Extensions or FilePaths should not empty");
                }
                else
                {
                    foreach (var filePath in filePaths)
                    {
                        if (System.IO.File.Exists(filePath))
                        {
                            UpdateDataJSON(filePath, extensions);
                        }
                        else
                        {
                            Console.WriteLine("{0} is not exists", filePath);
                        }
                    }
                }

            }
            Console.WriteLine("End to Update Data Extensions");
        }

        public static void UpdateDataJSON(string filePath, Dictionary<string, string> extensions)
        {
            try
            {
#pragma warning disable SCS0018
                var data = System.IO.File.ReadAllText(filePath);
#pragma warning restore SCS0018
                if (extensions != null && extensions.Count > 0)
                {
                    var dataObj = JsonConvert.DeserializeObject<IDictionary<string, Object>>(data);
                    foreach (var item in dataObj)
                    {
                        if (item.Key.Equals("dataconnectors", StringComparison.OrdinalIgnoreCase))
                        {
                            var extList = JsonConvert.DeserializeObject<IList<DataConnectorExt>>(item.Value.ToString());

                            foreach (var itemData in extList)
                            {
                                foreach (var extItem in extensions)
                                {
                                    if (extItem.Key.Equals(itemData.extType, StringComparison.OrdinalIgnoreCase))
                                    {
                                        itemData.accessibility.enterprise = true;
                                    }
                                }
                            }
                            dataObj[item.Key] = extList;
                            break;
                        }
                        else if (item.Key.Equals("appsettings", StringComparison.OrdinalIgnoreCase))
                        {
                            var appSettings = JsonConvert.DeserializeObject<IDictionary<string, Object>>(item.Value.ToString());
                            if (appSettings.ContainsKey("ExtAssemblies"))
                            {
                                var extensionAssemblies = appSettings["ExtAssemblies"] == null ? string.Empty : appSettings["ExtAssemblies"].ToString();
                                if (!string.IsNullOrEmpty(extensionAssemblies) && !extensionAssemblies.EndsWith(";") && extensions.Count > 0)
                                {
                                    extensionAssemblies += ";";
                                }

                                foreach (var extItem in extensions)
                                {
                                    if (string.IsNullOrEmpty(extItem.Value) || extensionAssemblies.IndexOf(extItem.Value, StringComparison.OrdinalIgnoreCase) != -1)
                                    {
                                        continue;
                                    }
                                    extensionAssemblies += extItem.Value + ";";
                                }

                                appSettings["ExtAssemblies"] = extensionAssemblies;
                                dataObj[item.Key] = appSettings;
                                break;
                            }
                        }
                    }
#pragma warning disable SCS0018
                    System.IO.File.WriteAllText(filePath, JsonConvert.SerializeObject(dataObj, Formatting.Indented));
#pragma warning restore SCS0018
                    Console.WriteLine("{0} is updated", filePath);
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine(ex.Message);
            }
        }
    }

    public class Accessibility
    {
        public bool cloud { get; set; }
        public bool enterprise { get; set; }
    }

    public class DataConnectorExt
    {
        public int category { get; set; }
        public string displayName { get; set; }
        public string description { get; set; }
        public string extType { get; set; }
        public string itemType { get; set; }
        public Accessibility accessibility { get; set; }
    }
}
