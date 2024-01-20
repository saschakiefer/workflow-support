#!python3
import json
import sys
import re

from termcolor import colored, cprint

test_messages = [
    '   2023-04-30T08:39:15.71+0200 [APP/PROC/WEB/0] OUT { "written_at":"2023-04-30T06:39:15.716Z","written_ts":1682836755716371000,"tenant_id":"-","component_id":"3c913ec3-63da-4832-ae62-4d54118d9777","component_name":"navigation-service","organization_name":"mainsub","component_type":"application","space_name":"lts","component_instance":"0","organization_id":"c45e1c2b-b218-416d-945e-04e2941593e9","correlation_id":"b46980bc-6e51-4993-8c0c-64cb6d59d3da","space_id":"ecde9397-fafa-4431-83e7-553dbe0215e1","container_id":"10.36.193.11","tenant_subdomain":"-","type":"log","logger":"com.sap.shell.services.navigation.client.ChangeRequestMessageListener","thread":"changeRequestMessageListenerContainer-1","level":"ERROR","categories":[],"msg":"MQ: processChange >> java.lang.IllegalArgumentException: SITEREFERENCES: is not supported. Dropping change for: sitereferences.default MODIFIED","stacktrace":["java.lang.IllegalArgumentException: SITEREFERENCES: is not supported. Dropping change for: sitereferences.default MODIFIED","\tat com.sap.shell.services.navigation.client.ChangeRequestMessageListener.applyChange(ChangeRequestMessageListener.java:248)","\tat com.sap.shell.services.navigation.client.ChangeRequestMessageListener.lambda$processChange$3(ChangeRequestMessageListener.java:154)","\tat com.sap.shell.services.navigation.core.context.CallerContextService.lambda$runWithCaller$0(CallerContextService.java:67)","\tat com.sap.shell.services.navigation.platform.logging.context.LoggingContextCallerContextListener.lambda$decorateCallerFunctionAfterContextSet$0(LoggingContextCallerContextListener.java:68)","\tat com.sap.shell.services.navigation.persistence.multitenancy.hooks.EntityManagerCallerContextListener.lambda$decorateCallerFunctionAfterContextSet$0(EntityManagerCallerContextListener.java:64)","\tat org.springframework.transaction.support.TransactionTemplate.execute(TransactionTemplate.java:140)","\tat com.sap.shell.services.navigation.persistence.multitenancy.hooks.EntityManagerCallerContextListener.lambda$decorateCallerFunctionAfterContextSet$1(EntityManagerCallerContextListener.java:64)","\tat com.sap.shell.services.navigation.core.context.CallerContextService.lambda$runWithCaller$2(CallerContextService.java:101)","\tat com.sap.shell.services.navigation.core.context.CallerContextService.runWithCaller(CallerContextService.java:117)","\tat com.sap.shell.services.navigation.core.context.CallerContextService.runWithCaller(CallerContextService.java:66)","\tat com.sap.shell.services.navigation.client.ChangeRequestMessageListener.processChange(ChangeRequestMessageListener.java:115)","\tat com.sap.shell.services.navigation.client.ChangeRequestMessageListener.onMessage(ChangeRequestMessageListener.java:81)","\tat com.sap.shell.services.navigation.platform.logging.correlation.FreshCorrelationIdWrapper.lambda$wrap$1(FreshCorrelationIdWrapper.java:53)","\tat com.sap.shell.services.navigation.platform.logging.correlation.FreshCorrelationIdWrapper.lambda$wrap$0(FreshCorrelationIdWrapper.java:39)","\tat com.sap.shell.services.navigation.platform.logging.correlation.FreshCorrelationIdWrapper.lambda$wrap$2(FreshCorrelationIdWrapper.java:54)","\tat com.sap.shell.services.navigation.client.configuration.MQConfiguration.lambda$changeRequestMessageListenerContainer$0(MQConfiguration.java:60)","\tat org.springframework.jms.listener.AbstractMessageListenerContainer.doInvokeListener(AbstractMessageListenerContainer.java:761)","\tat org.springframework.jms.listener.AbstractMessageListenerContainer.invokeListener(AbstractMessageListenerContainer.java:699)","\tat org.springframework.jms.listener.AbstractMessageListenerContainer.doExecuteListener(AbstractMessageListenerContainer.java:674)","\tat org.springframework.jms.listener.AbstractPollingMessageListenerContainer.doReceiveAndExecute(AbstractPollingMessageListenerContainer.java:331)","\tat org.springframework.jms.listener.AbstractPollingMessageListenerContainer.receiveAndExecute(AbstractPollingMessageListenerContainer.java:270)","\tat org.springframework.jms.listener.DefaultMessageListenerContainer$AsyncMessageListenerInvoker.invokeListener(DefaultMessageListenerContainer.java:1237)","\tat org.springframework.jms.listener.DefaultMessageListenerContainer$AsyncMessageListenerInvoker.executeOngoingLoop(DefaultMessageListenerContainer.java:1227)","\tat org.springframework.jms.listener.DefaultMessageListenerContainer$AsyncMessageListenerInvoker.run(DefaultMessageListenerContainer.java:1120)","\tat java.base/java.lang.Thread.run(Unknown Source)"] }',
    'test',
    '   2023-04-30T08:39:16.76+0200 [APP/PROC/WEB/0] OUT { "written_at":"2023-04-30T06:39:16.766Z","written_ts":1682836756766046000,"tenant_id":"-","component_id":"3c913ec3-63da-4832-ae62-4d54118d9777","component_name":"navigation-service","organization_name":"mainsub","component_type":"application","space_name":"lts","component_instance":"0","organization_id":"c45e1c2b-b218-416d-945e-04e2941593e9","correlation_id":"fbc48c21-b1f7-47f7-931d-be7e1ecbff62","space_id":"ecde9397-fafa-4431-83e7-553dbe0215e1","container_id":"10.36.193.11","tenant_subdomain":"-","type":"log","logger":"com.sap.shell.services.navigation.client.ChangeRequestMessageListener","thread":"changeRequestMessageListenerContainer-1","level":"INFO","categories":[],"msg":" MQ: Incoming message on topic: cdm/site/entities/deleted" }',
    """   2023-04-30T08:43:34.02+0200 [APP/PROC/WEB/2] OUT [SERVICE: InfluxDB] Couldn't write to server: 404 Not Found: Requested route ('ng-router-dashboard-influxdb.cfapps.eu12.hana.ondemand.com') does not exist.""",
    """   2024-01-20T09:37:58.99+0100 [RTR/6] OUT portal-service-wz-saki-providerprov1.cfapps.eu12.hana.ondemand.com - [2024-01-20T08:37:58.990006873Z] "GET /navigation/internal/v1/cache/invalidate HTTP/1.1" 200 0 2 "-" "ReactorNetty/1.1.15" "10.0.72.3:34812" "10.0.201.14:61242" x_forwarded_for:"165.1.187.202, 10.0.72.3" x_forwarded_proto:"https" vcap_request_id:"a0512cb1-0b33-478b-4097-a08d385270a3" response_time:0.007945 gorouter_time:0.000042 app_id:"1a9ecb5c-150a-4d97-9e25-75e276402844" app_index:"0" instance_id:"1e72a1c7-e4de-4fbf-51f8-70ca" failed_attempts:0 failed_attempts_time:"-" dns_time:0.000000 dial_time:0.000000 tls_time:0.000000 backend_time:0.007904 x_cf_routererror:"-" x_correlationid:"-" tenantid:"-" sap_passport:"-" x_scp_request_id:"8fba0da0-1476-4704-9f12-e02ed562c15b-65AB8666-22FCF38" x_cf_app_instance:"-" x_forwarded_host:"-" x_custom_host:"-" x_ssl_client:"-" x_ssl_client_session_id:"-" x_ssl_client_verify:"-" x_ssl_client_subject_dn:"-" x_ssl_client_subject_cn:"-" x_ssl_client_issuer_dn:"-" x_ssl_client_notbefore:"-" x_ssl_client_notafter:"-" x_cf_forwarded_url:"-" traceparent:"-" x_b3_traceid:"a0512cb10b33478b4097a08d385270a3" x_b3_spanid:"4097a08d385270a3" x_b3_parentspanid:"-" b3:"a0512cb10b33478b4097a08d385270a3-4097a08d385270a3"""
]

def extract_external_call_substring(input_string):
    # Define the regex pattern to match the specified format ("external call parameters" 200 0 2 ")
    pattern = re.compile(r'^[^\s]+ - \[.*\] "(.*?)" (\d+ \d+ \d+)')

    # Try to find a match in the input string
    match = pattern.match(input_string)

    if match:
        # Extract the substring between the first and third double quotes and remove quotes in between
        result = match.group(1) + ' ' + match.group(2)
        return result
    else:
        return input_string

def get_parsed_message(log):
    message_parts = log.lstrip().split(" OUT ")

    if len(message_parts) < 2:
        return {
            "level": "ERROR",
            "message": "Invalid log input, could not extract message: " + log,
            "stacktrace": None,
            "timestamp": "",
            "time": "",
            "process": "",
            "logger": ""
        }

    parsed_message = None
    stacktrace = None
    log_level = None
    logger = None
    try:
        prepped_message = message_parts[1].replace("\t", "    ")
        json_message = json.loads(prepped_message)
        parsed_message = json_message["msg"]
        log_level = json_message["level"]

        # limit to the length to 20 and replace the middle part by ... if needed
        logger = json_message["logger"].split('.')[-1]
        logger = logger.split('.')[-1][:10] + '...' + logger.split('.')[-1][-17:] if len(logger.split('.')[-1]) > 30 else logger.split('.')[-1]

        if hasattr(json_message, "stacktrace"):
            stacktrace = "\n".join(json_message["stacktrace"])
    except:
        parsed_message = extract_external_call_substring(message_parts[1])

    return {
        "level": log_level,
        "message": parsed_message,
        "stacktrace": stacktrace,
        "timestamp": message_parts[0][:27],
        "time": message_parts[0][11:27],
        "process": message_parts[0][28:],
        "logger": logger
    }


def get_level_color(level):
    color = "white"
    text = level

    if level == "ERROR":
        color = "red"
    elif level == "WARN" or level == "WARNING":
        color = "yellow"
    elif level == "INFO":
        color = "green"
    elif level == "DEBUG":
        color = "white"
    elif level == "TRACE":
        color = "dark_grey"

    return color


def print_message(parsed_message):
    if parsed_message["level"] is None:
        level = ""
    else:
        level = parsed_message["level"]

    if parsed_message["logger"] is None:
        logger = ""
    else:
        logger = parsed_message["logger"]

    text = (
            colored("{:>16}".format(parsed_message["time"]), "dark_grey")
            + " "
            + colored("{:<30}".format(logger), "dark_grey")
            + " "
            + colored("{:>7}".format(level), get_level_color(level))
            + " "
            + colored(parsed_message["message"], "white")
    )
    print(text)

    if not parsed_message["stacktrace"] is None:
        print(colored(parsed_message["stacktrace"], "dark_grey"))

def test():
    for test_message in test_messages:
        print_message(get_parsed_message(test_message))

if __name__ == "__main__":
    if "--test" in sys.argv:
        test()
        sys.exit()

    if "--skip-ff-log" in sys.argv:
        skip_ff_log = True
    else:
        skip_ff_log = False

    for line in sys.stdin:
        if (line != "" and line != "\n"):
            parsed_message = get_parsed_message(line)

            if skip_ff_log and parsed_message["logger"] == "CoreFeatur...PortalTenantLogic":
                continue

            print_message(parsed_message)
