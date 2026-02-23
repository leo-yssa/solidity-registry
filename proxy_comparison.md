# Proxy Patterns Comparison

This document compares the three major proxy patterns supported by OpenZeppelin for creating upgradeable smart contracts: **Transparent Proxy**, **UUPS (Universal Upgradeable Proxy Standard)**, and **Beacon Proxy**.

## 1. Transparent Proxy Pattern

The Transparent Proxy pattern separates admin logic and user logic by checking the caller's address. If the caller is the proxy admin, the proxy resolves admin functions (like `upgradeTo`). If the caller is any other address, the proxy delegates the call to the implementation contract.

**Pros:**
- **Standardized:** It has been the most common proxy pattern for a long time.
- **Fail-safe:** The proxy contract itself contains the upgrade logic, meaning even if a buggy implementation is deployed, the admin can still upgrade it because the upgrade logic lives within the proxy.

**Cons:**
- **High Deployment Cost:** The proxy contract itself is relatively large and expensive to deploy.
- **High Execution Cost:** Every user interaction incurs an additional `SLOAD` operation to check the admin address, increasing gas costs for every transaction.
- **ProxyAdmin Contract:** Requires a separate `ProxyAdmin` contract to manage all transparent proxies securely, adding to the structural overhead.

---

## 2. UUPS (Universal Upgradeable Proxy Standard) Pattern

Proposed in EIP-1822, UUPS is highly similar to the transparent proxy pattern, but places the upgrade logic inside the **Implementation** contract instead of the proxy itself. The Proxy is solely responsible for routing delegate-calls.

**Pros:**
- **Cheaper Deployment:** The proxy is a minimal EIP-1967 proxy, making deployment significantly cheaper than Transparent Proxies.
- **Lower Execution Cost:** Since the proxy doesn't need to check whether the caller is an admin on every call, the gas overhead per transaction is significantly reduced.
- **Flexibility:** Developers can customize the upgrade mechanism (e.g., adding a timelock or multisig condition) within the implementation's `_authorizeUpgrade` function.

**Cons:**
- **Risk of Bricking:** Because the upgrade logic exists inside the implementation contract, if an implementation is deployed without the upgrade logic or with a bug in `_authorizeUpgrade`, the proxy can be "bricked" and permanently lose its upgradeability.
- **Implementation Complexity:** Developers must remember to inherit `UUPSUpgradeable` and correctly override `_authorizeUpgrade` in every new implementation.

---

## 3. Beacon Proxy Pattern

The Beacon Proxy pattern introduces a third component: the **Beacon** contract. The Beacon holds the address of the current implementation. Proxies do not store the implementation address themselves; instead, they query the Beacon on every call.

**Pros:**
- **Mass Upgrades:** When the administrator updates the implementation address inside the Beacon contract, **all** Beacon Proxies connected to that Beacon are simultaneously upgraded.
- **Scalability:** Highly efficient when an application needs to deploy numerous identical proxies (e.g., thousands of user wallets or organizational vaults).

**Cons:**
- **Slightly Higher Execution Cost:** The proxy must make an external call to the Beacon to fetch the implementation address before doing a `delegatecall`, increasing the gas cost of each transaction compared to UUPS.
- **Complex Architecture:** Requires deploying and managing three layers: Proxy, Beacon, and Implementation.

---

## Summary and Recommendations

| Feature | Transparent | UUPS | Beacon |
| :--- | :--- | :--- | :--- |
| **Upgrade Logic Location** | Proxy | Implementation | Beacon |
| **Upgrade Scope** | Single Proxy | Single Proxy | Multiple Proxies at once |
| **Deployment Gas Cost** | High | Low | Medium (Requires Beacon) |
| **Execution Overhead** | High | Low | Highest (Extra Call) |
| **Risk of Bricking Upgrade** | Low | High | Low |

### When to use which?
1. **Use UUPS** when you need a single proxy instance that requires the cheapest gas execution and deployment costs. It is modern and highly recommended by OpenZeppelin.
2. **Use Beacon** when you need to deploy many proxy instances of the exact same contract and want the ability to upgrade all of them with a single transaction.
3. **Use Transparent Proxy** if your team strictly requires the upgrade logic to be isolated from the logic contract to prevent bricking, though it comes at the penalty of higher gas costs.
